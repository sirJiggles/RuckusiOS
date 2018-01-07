//
//  TimableController.swift
//  ruckus
//
//  Created by Gareth on 29.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit

protocol TimableVCDelegate: class {
    func resetUI() -> Void
    func setColours() -> Void
    func setUpSwitchModesUI() -> Void
    func updateCircuitNumberUI(to newValue: Double, circuitNumber: Int) -> Void
    func startWorkoutUI() -> Void
    func didTickUISecond(time: String, mode: TimerMode) -> Void
    func tick(newValue: Double) -> Void
    
    // cannot have optional functions (without objc mentalness)
    //, but if I could they would be here :(
    func settingsSyncUI() -> Void
    func finnishedUI() -> Void
    func didStartUI() -> Void
    func stopWorkoutUI() -> Void
    func pauseWorkoutUI() -> Void
    func didFinishPlayingCombo() -> Void
}

// this moves much of the functionality away from the VC
class TimableController: UIViewController, IntervalTimerDelegate, ListensToPlayEndEvents {
    
    var timer: IntervalTimer
    var notificationBridge: WatchNotificationBridge
    let intervalTimerSettings: IntervalTimerSettingsHelper
    var comboTimer: Timer?
    
    var soundPlayer = SoundPlayer.sharedInstance
    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
    let workoutSession = WorkoutSession.sharedInstance
    var settingsAccessor: SettingsAccessor?
    
    var paused: Bool = false
    var wasPaused: Bool = false
    var running: Bool = false
    var callOutsEnabled: Bool = false
    var comboPauseTime: Double = 1.0
    var aboutToSwitch: Bool = false
    var crowedSoundsEnabled: Bool = false
    
    weak var timerVCDelegate: TimableVCDelegate?
    
    var isVRVC: Bool = false
    
    
    init() {
        timer = IntervalTimer.sharedInstance
        notificationBridge = WatchNotificationBridge.sharedInstance
        intervalTimerSettings = IntervalTimerSettingsHelper()
        settingsAccessor = SettingsAccessor()
        
        // set the state of the flags at the start
        paused = timer.paused
        running = timer.running
        super.init(nibName: nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        timer = IntervalTimer.sharedInstance
        notificationBridge = WatchNotificationBridge.sharedInstance
        intervalTimerSettings = IntervalTimerSettingsHelper()
        settingsAccessor = SettingsAccessor()
        
        // set the state of the flags at the start
        paused = timer.paused
        running = timer.running
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        aboutToSwitch = false
        updateTimer()
        updateDifficultyAndVolume()
        
        // need to reset the delegates each time!
        timer.delegate = self
        soundPlayer.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // stop the workout regardless from now on
        stopWorkout()
    }
    
    // unsub and re-subscribe to notifications
    func setUpNotifications() {
        // Notifications
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.StartWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startFromWatch(_:)),
            name: NSNotification.Name(NotificationKey.StartWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.PauseWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseFromWatch(_:)),
            name: NSNotification.Name(NotificationKey.PauseWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.StopWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopFromWatch),
            name: NSNotification.Name(NotificationKey.StopWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didGetSettingsSync),
            name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.ShowFinishedScreenFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showDoneFromWatch(_:)),
            name: NSNotification.Name(NotificationKey.ShowFinishedScreenFromWatch.rawValue),
            object: nil
        )
    }
    
    // MARK: - timer util functions
    func updateTimer() {
        let settings = intervalTimerSettings.getSettings()
        timer.updateSettings(settings: settings)
    }
    
    func updateDifficultyAndVolume() {
        if let callOutSetting = settingsAccessor?.getCallOuts() {
            callOutsEnabled = callOutSetting
        }
        
        if let crowedEnabledSetting = settingsAccessor?.getCrowdEnabled() {
            // incase it is running
            if (!crowedEnabledSetting) {
                stopCrowd()
                crowedSoundsEnabled = false
            } else {
                crowedSoundsEnabled = true
                // if it is running and in working mode, start the crowd again
                if timer.currentMode == .working && running {
                    startCrowd()
                }
            }
        }
        
        comboPauseTime = (isVRVC) ? 4.0 : 1.0
        
        // update the difficulty, this is how often we will call our combos
        if let difficultySetting = settingsAccessor?.getDifficulty() {
            // this is the time offset for calling out the hits (beetween 4 and 0.5 seconds)
            if isVRVC {
                // plus 3 seconds for the AR combo
                comboPauseTime = Double((4 - (3.5 * difficultySetting)) + 3.0)
            } else {
                comboPauseTime = Double(4 - (3.5 * difficultySetting))
            }
        }
        // set the volume on the sound player shared instance
        if let volumeSetting = settingsAccessor?.getVolume() {
            soundPlayer.setNewVolume(volumeSetting)
        }
        // if the voice style has changed
        HitCaller.sharedInstance.updateVoiceStyle()
    }
    
    // MARK Notification functions like from watch
    
    @objc func startFromWatch(_ payload: Notification) {
        if let data = payload.userInfo as? [String: NSDate], let timestamp = data["startTime"] {
            DispatchQueue.main.async {
                self.workoutStoreHelper.workoutStartDate = timestamp as Date
                self.startWorkout(timestamp)
            }
        }
    }
    func startWorkout(_ timestamp: NSDate) {
        if running {
            return
        }
        // if it was paused and the current mode is working, start the hit caller again
        if (paused && timer.currentMode == .working) {
            if callOutsEnabled {
                if (comboTimer != nil) {
                    comboTimer?.invalidate()
                }
                comboTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
            }
        }
        
        // so we know on cb from dlegate that was paused
        if paused {
            wasPaused = true
        }
        
        running = true
        paused = false
        
        DispatchQueue.main.async {
            self.timer.start(timestamp)
        }
        
        // upadte the UI to state the change in started workout mode
        timerVCDelegate?.startWorkoutUI()
    }
    
    
    @objc func stopFromWatch() {
        DispatchQueue.main.async {
            self.stopWorkout()
        }
    }
    func stopWorkout() {
        stopCrowd()
        timer.stop()
        timerVCDelegate?.resetUI()
        paused = false
        running = false
        timerVCDelegate?.stopWorkoutUI()
    }
    
    @objc func pauseFromWatch(_ payload: Notification) {
        if let data = payload.userInfo as? [String: NSDate], let timestamp = data["pauseTime"] {
            DispatchQueue.main.async {
                do {
                    try self.soundPlayer.play("pause", withExtension: "wav")
                } catch let error {
                    fatalError(error.localizedDescription)
                }
                self.pauseWorkout(timestamp)
                self.timerVCDelegate?.pauseWorkoutUI()
            }
        }
    }
    
    // called from the watch to show the finnished screen when not connected to a watch session
    @objc func showDoneFromWatch(_ payload: Notification) {
        
        // get the summary information and use it to pass to the next screen
        guard let summary = payload.userInfo as? [String:String] else {
            fatalError("summary payload of wrong type for finished screen")
        }
        
        DispatchQueue.main.async {
            // reset the UI and stop the timer!
            self.stopWorkout()
            self.performSegue(withIdentifier: "workoutFinishedFromTimer", sender: summary)
        }
    }
    
    func pauseWorkout(_ timestamp: NSDate?) {
        if paused {
            return
        }
        stopCrowd()
        paused = true
        running = false
        timer.pause(timestamp)
        timerVCDelegate?.pauseWorkoutUI()
    }
    
    func pauseWorkoutTimer() {
        timer.pause(nil)
        running = false
        timerVCDelegate?.pauseWorkoutUI()
    }
    
    func getAuthAndBeginWorkout() {
        
        workoutStoreHelper.getAuth { (authorized, error) -> Void in
            if (authorized) {
                self.workoutStoreHelper.startWorkout()
            } else {
                // iPad
                self.workoutStoreHelper.workoutStartDate = Date()
            }
            // go back to the main thread to start the workout (even if not authorized)
            DispatchQueue.main.async (execute: {
                self.startWorkout(NSDate())
            })
        }
    }
    
    func proceedWithPlayClick() {
        if notificationBridge.sessionReachable() {
            // wait for the watch to tell us it was ok to start the workout (auth etc) we dont start it here
            notificationBridge.sendMessage(.StartWorkoutFromApp, callback: nil)
            // also always start a workout on the phone just incase we loose connection
            // with the watch during it!
            self.workoutStoreHelper.startWorkout()
        } else {
            getAuthAndBeginWorkout()
        }
    }
    
    // this gets called befoe we segue away
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "workoutFinishedFromTimer" {
            if let summaryData = sender as? [String:String] {
                let vc = segue.destination as! WorkoutFinishedViewController
                vc.summaryData = summaryData
            }
        }
    }
    
    // MARK: = Interval timer delegate hooks
    @objc func didGetSettingsSync() {
        updateTimer()
        updateDifficultyAndVolume()
    }
    
    @objc func runComboAfterTime() {
        // here we work out if still playing and in working mode, and the difficulty etc
        // we use this information to decide on how fast to pick and if to play a combo or not
        if (self.timer.currentMode != .working) {
            return
        }
        if (!self.running) {
            return
        }
        if (!self.callOutsEnabled) {
            return
        }
        
        // if about to switch dont start a new combo
        if (self.aboutToSwitch) {
            return
        }
        
        HitCaller.sharedInstance.runCombo()
    }
    
    // MARK: - Delegate functions for Sound player
    func didFinishPlaying() {
        
        // to make sure there is no overlap of combos!
        if (comboTimer != nil) {
            comboTimer?.invalidate()
        }
        
        // if we have a finished playing delegate like the AR player, let it know it's time
        timerVCDelegate?.didFinishPlayingCombo()
        
        comboTimer = Timer.scheduledTimer(timeInterval: comboPauseTime, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
    }
    
    
    // MARK: - Delegate functions for Ruckus timer
    func didTickSecond(time: String, mode: TimerMode) {
        // just let the UI know
        timerVCDelegate?.didTickUISecond(time: time, mode: mode)
    }
    
    func updateCircuitNumber(to: Double, circuitNumber: Int) {
        // again just pass on to the delegate
        timerVCDelegate?.updateCircuitNumberUI(to: to, circuitNumber: circuitNumber)
    }
    
    func tickRest(newValue: Double) {
        timerVCDelegate?.tick(newValue: newValue)
    }
    
    func tickPrep(newValue: Double) {
        timerVCDelegate?.tick(newValue: newValue)
    }
    
    func tickStretch(newValue: Double) {
        timerVCDelegate?.tick(newValue: newValue)
    }
    
    func tickWarmUp(newValue: Double) {
        timerVCDelegate?.tick(newValue: newValue)
    }
    
    func tickWork(newValue: Double) {
        // pass the new value allong to the util func
        timerVCDelegate?.tick(newValue: newValue)
    }
    
    // called when we switch modes
    func reset() {
        playRoundEndSound()
        timerVCDelegate?.setColours()
        setUpSwitchModes()
        aboutToSwitch = false
    }
    
    func startCrowd() {
        if !crowedSoundsEnabled {
            return
        }
        if soundPlayer.looping {
            return
        }
        // start the sound for the crowd if the setting is turned on
        do {
            try soundPlayer.play("crowd", withExtension: "wav", loop: true)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func stopCrowd() {
        if !crowedSoundsEnabled {
            return
        }
        if (soundPlayer.looping) {
            soundPlayer.loopingPlayer.stop()
            soundPlayer.looping = false
        }
    }
    
    func playRoundEndSound() {
        var sound = ""
        var ext = ""
        switch timer.currentMode {
        case .working:
            sound = "bell"
            ext = "mp3"
            startCrowd()
        default:
            sound = "round-end"
            ext = "wav"
        }
        
        do {
            try soundPlayer.play(sound, withExtension: ext)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    // when done the workout
    func finished() {
        stopCrowd()
        paused = false
        running = false
        // only show done if not on watch session, else watch will handle it
        if !notificationBridge.sessionReachable() {
            performSegue(withIdentifier: "workoutFinishedFromTimer", sender: nil)
        }
        timerVCDelegate?.resetUI()
        timerVCDelegate?.finnishedUI()
    }
    
    func aboutToSwitchModes() {
        // used so we know not to keep calling out combos
        aboutToSwitch = true
    }
    
    func setUpSwitchModes() {
        switch (timer.currentMode) {
        case .preparing:
            workoutSession.pause()
        case .resting:
            workoutSession.pause()
        case .stretching:
            workoutSession.pause()
        case .warmup:
            workoutSession.resume()
        case .working:
            workoutSession.resume()
            
            if callOutsEnabled {
                
                if (comboTimer != nil) {
                    comboTimer?.invalidate()
                }
                // start the combo calling after a second
                comboTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
            }
        }
        
        // run any UI changes required in the delegate
        timerVCDelegate?.setUpSwitchModesUI()
    }
    
    // reset the rings
    func didStart() {
        // only do the following if not was paused
        if wasPaused {
            wasPaused = false
            startCrowd()
            return
        }
        
        var sound = ""
        var ext = ""
        if (timer.currentMode == .working) {
            sound = "bell"
            ext = "mp3"
            
            startCrowd()
        } else {
            sound = "round-end"
            ext = "wav"
        }
        do {
            try soundPlayer.play(sound, withExtension: ext)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        timerVCDelegate?.setColours()
        setUpSwitchModes()
        timerVCDelegate?.didStartUI()
    }
}
