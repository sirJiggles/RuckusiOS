//
//  FirstViewController.swift
//  ruckus
//
//  Created by Gareth on 01/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import MKRingProgressView
import HealthKit
import GoogleMobileAds

class TimerViewController: UIViewController, IntervalTimerDelegate, GADInterstitialDelegate, ListensToPlayEndEvents {
    
    var ruckusTimer: IntervalTimer
    var notificationBridge: WatchNotificationBridge
    let intervalTimerSettings: IntervalTimerSettingsHelper
    var comboTimer: Timer?
    
    var interstitial: GADInterstitial!
    
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
    
    var ringCurrent: Double = 0.0
    var roundIcons: [UIView] = []
    
    @IBOutlet weak var timeSectionView: UIView!
    @IBOutlet weak var ring: MKRingProgressView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var modeLabel: UILabel!
    
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseStopContainer: UIView!
    
    // this is what we insert the round marks into
    @IBOutlet weak var roundsContainer: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        ruckusTimer = IntervalTimer.sharedInstance
        notificationBridge = WatchNotificationBridge.sharedInstance
        intervalTimerSettings = IntervalTimerSettingsHelper()
        settingsAccessor = SettingsAccessor()
        
        super.init(coder: aDecoder)
        // set up the delgate for listening to sound end events
        soundPlayer.delegate = self
        // delgate for listening to timer events
        ruckusTimer.delegate = self
    }
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.StartWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(self,
           selector: #selector(startFromWatch(_:)),
           name: NSNotification.Name(NotificationKey.StartWorkoutFromWatch.rawValue),
           object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.PauseWorkoutFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(self,
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
        
        // set up the full page add, if not paid and have internet connection
        if PurchasedState.sharedInstance.isPaid == false && currentReachabilityStatus != .notReachable{
            createAndLoadInterstitial()
        }
        
        // set the size of the rings and spacing for larger screens
        ring.progress = 0
        
        // iPadPro 12: 1024.0
        // iPadPro 9.7 / iPadAir / iPadAir2: 768.0
        let size = UIScreen.main.bounds
        
        calcAndSetRingSize(width: size.width, height: size.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        aboutToSwitch = false
        updateTimer()
        setUpRoundIcons()
        updateDifficultyAndVolume()
    }
    
    // will go into various rotation modes in iPad large portrait
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.calcAndSetRingSize(width: size.width, height: size.height)
        }) { (context) in
            // after, if we need to clean anything up, dont think we will though
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    // util functions for updating the timer and so on
    func updateTimer() {
        let settings = intervalTimerSettings.getSettings()
        ruckusTimer.updateSettings(settings: settings)
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
                if ruckusTimer.currentMode == .working && running {
                    startCrowd()
                }
            }
        }
        
        // update the difficulty, this is how often we will call our combos
        if let difficultySetting = settingsAccessor?.getDifficulty() {
            // this is the time offset for calling out the hits (beetween 4 and 0.5 seconds)
            comboPauseTime = Double(4 - (3.5 * difficultySetting))
        }
        // set the volume on the sound player shared instance
        if let volumeSetting = settingsAccessor?.getVolume() {
            soundPlayer.setNewVolume(volumeSetting)
        }
        // if the voice style has changed
        HitCaller.sharedInstance.updateVoiceStyle()
    }
    
    
    @objc func didGetSettingsSync() {
        updateTimer()
        updateDifficultyAndVolume()
        // might also need to update the rounds area (in main thread)
        DispatchQueue.main.async {
            self.setUpRoundIcons()
        }
    }
    
    @objc func runComboAfterTime() {
        // here we work out if still playing and in working mode, and the difficulty etc
        // we use this information to decide on how fast to pick and if to play a combo or not
        if (self.ruckusTimer.currentMode != .working) {
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
        
        comboTimer = Timer.scheduledTimer(timeInterval: comboPauseTime, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
    }

    
    // MARK: - Delegate functions for Ruckus timer
    func didTickSecond(time: String, mode: TimerMode) {
        timeLabel.text = time
    }
    
    func tickRest(newValue: Double) {
        tick(newValue: newValue)
    }
    
    func tickPrep(newValue: Double) {
        tick(newValue: newValue)
    }
    
    func tickStretch(newValue: Double) {
        tick(newValue: newValue)
    }
    
    func tickWarmUp(newValue: Double) {
        tick(newValue: newValue)
    }
    
    func tickWork(newValue: Double) {
        // pass the new value allong to the util func
        tick(newValue: newValue)
    }
    
    // called when we switch modes
    func reset() {
        playRoundEndSound()
        setColours()
        setUpSwitchModes()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = 0
        CATransaction.commit()
        ringCurrent = 0
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
        switch ruckusTimer.currentMode {
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
    
    func tick(newValue: Double) -> Void {
        // update the ring, always
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        ring.progress = newValue
        CATransaction.commit()
        ringCurrent = newValue
    }
    
    func updateCircuitNumber(to newValue: Double, circuitNumber: Int) {
        if roundIcons.indices.contains(circuitNumber - 1) {
            roundIcons[circuitNumber - 1].backgroundColor = UIColor.white
        }
    }
    
    // when done the workout
    func finished() {
        stopCrowd()
        showPlayButton()
        paused = false
        running = false
        // only show done if not on watch session, else watch will handle it
        if !notificationBridge.sessionReachable() {
            performSegue(withIdentifier: "workoutFinishedFromTimer", sender: nil)
        }
        resetUI()
    }
    
    func aboutToSwitchModes() {
        // used so we know not to keep calling out combos
        aboutToSwitch = true
    }
    
    func setUpSwitchModes() {
        timeLabel.text = "00:00"
        switch (ruckusTimer.currentMode) {
        case .preparing:
            modeLabel.text = "Prepare"
            workoutSession.pause()
        case .resting:
            modeLabel.text = "Resting"
            workoutSession.pause()
        case .stretching:
            modeLabel.text = "Stretch"
            workoutSession.pause()
        case .warmup:
            workoutSession.resume()
            modeLabel.text = "Warmup"
        case .working:
            workoutSession.resume()
            
            if callOutsEnabled {
                
                if (comboTimer != nil) {
                    comboTimer?.invalidate()
                }
                // start the combo calling after a second
                comboTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
            }
            
            modeLabel.text = "Working"
        }
            
    }
    
    func setColours() {
        switch (ruckusTimer.currentMode) {
        case .preparing:
            modeLabel.textColor = UIColor.lightGreen
            timeLabel.textColor = UIColor.lightGreen
        case .resting, .stretching:
            modeLabel.textColor = UIColor.lightestBlue
            timeLabel.textColor = UIColor.lightestBlue
        case .working, .warmup:
            modeLabel.textColor = UIColor.theOrange
            timeLabel.textColor = UIColor.theOrange
        }
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
        if (ruckusTimer.currentMode == .working) {
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
        
        
        setColours()
        setUpSwitchModes()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        self.ring.progress = 0
        CATransaction.commit()
    }
    
    
    
    // MARK: - Delegate for the full page ad
    func createAndLoadInterstitial() {
        if (Flags.live.rawValue == 1) {
            interstitial = GADInterstitial(adUnitID: AdIdents.fullPageOnTimer.rawValue)
        } else {
            interstitial = GADInterstitial(adUnitID: AdIdents.debugFullPage.rawValue)
        }
        
        interstitial.delegate = self
        interstitial.load(GADRequest())
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        // make a new ad
        createAndLoadInterstitial()
        
        // let user porceed with play
        proceedWithPlayClick()
    }

    
    // MARK: - View functions like clicking buttons
    func repositionAmbiguous() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = ringCurrent + 1
        CATransaction.commit()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = ringCurrent
        CATransaction.commit()
    }
    
    func calcAndSetRingSize(width: CGFloat, height: CGFloat) {
        
        switch (width, height) {
        // 12.9 inch iPad port
        case (let w, let h) where w == 1024.0 && h == 1366.0:
            ring.ringWidth = 70
            timeLabel.font = UIFont(name: "Impact", size: 300)
            modeLabel.font = UIFont(name: "Impact", size: 60)
            setUpRoundIcons()
            break
        // 12.9 inch iPad, land
        case (let w, let h) where h == 1024.0 && w == 1366.0:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 10.5 inch iPad port
        case (let w, let h) where h == 1112.0 && w == 834.0:
            timeLabel.font = UIFont(name: "Impact", size: 200)
            modeLabel.font = UIFont(name: "Impact", size: 55)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 10.5 inch iPad land
        case (let w, let h) where h == 834.0 && w == 1112.0:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 9.7 inch iPad port
        case (let w, let h) where w == 768.0 && h == 1024.0:
            ring.ringWidth = 50
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            break
        // 9.7 inch iPad land
        case (let w, let h) where h == 768.0 && w == 1024.0:
            timeLabel.font = UIFont(name: "Impact", size: 155)
            modeLabel.font = UIFont(name: "Impact", size: 45)
            ring.ringWidth = 35
            setUpRoundIcons()
            break
        // 6 / 7 +
        case (let w, _) where w == 414:
            ring.ringWidth = 34
            timeLabel.font = UIFont(name: "Impact", size: 150)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            break
        // 6 / 7
        case (let w, _) where w == 375:
            ring.ringWidth = 28
            timeLabel.font = UIFont(name: "Impact", size: 130)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            break
        // 5 and bellow
        case (_, let h) where h <= 568:
            ring.ringWidth = 25
            timeLabel.font = UIFont(name: "Impact", size: 110)
            modeLabel.font = UIFont(name: "Impact", size: 25)
            break
        // some default font size handling for saftey
        case (let w, _) where w >= 700:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            repositionAmbiguous()
            break
        default:
            timeLabel.font = UIFont(name: "Impact", size: 130)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            setUpRoundIcons()
            repositionAmbiguous()
            break
        }

    }
    
    // create the icons for the rounds
    func setUpRoundIcons() {
        // now we need to remove all the icons that may have already been there
        for icon in roundIcons {
            icon.removeFromSuperview()
        }
        // clear out the array
        roundIcons = []
        
        var amountOfRounds = ruckusTimer.intervals
        let segmentSize = Double(roundsContainer.frame.width) / amountOfRounds
        let maxHeight = Double(roundsContainer.frame.height / 2)
        var height = segmentSize + (segmentSize * 0.3)
        height = (height > maxHeight) ? maxHeight : height
        let yPos = (Double(roundsContainer.frame.midY) - (height / 2))
        let space = 5.0
        let cornerSize = segmentSize / amountOfRounds
        let cornerRadius = CGFloat((cornerSize > 5) ? 5 : cornerSize)
        // start the x off at 10 from the left of the container
        var previousX = 0.0
        
        while amountOfRounds > 0 {
            // create a new view for each round
            let size = CGSize(width: segmentSize - space, height: height)
            // put the x is in the right place and add it in the middle of the view
            let origin = CGPoint(x: CGFloat(previousX), y: CGFloat(yPos))
            let frame = CGRect(origin: origin, size: size)
            let view = UIView(frame: frame)
            view.layer.cornerRadius = cornerRadius
            view.backgroundColor = UIColor.greyOne
            // add the view to our array so we can mark it as complete
            roundIcons.append(view)
            roundsContainer.addSubview(view)
            previousX = (previousX + segmentSize)
            amountOfRounds = amountOfRounds - 1
        }
        
        // update the color of the rounds that are done, incase we removed them by mistake
        var amountDone = Int(ruckusTimer.intervalsDone)
        while amountDone > 0 {
            roundIcons[amountDone - 1].backgroundColor = UIColor.white
            amountDone = amountDone - 1
        }
    }
    
    
    func hidePlayButton() {
        playBtn.isHidden = true
        pauseStopContainer.isHidden = false
    }
    
    func showPlayButton() {
        playBtn.isHidden = false
        pauseStopContainer.isHidden = true
    }
    
    func resetUI() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = 0
        CATransaction.commit()
        timeLabel.text = "00:00"
        timeLabel.textColor = UIColor.greyOne
        modeLabel.isHidden = true
        // reset the colors for the icons
        for icon in roundIcons {
            icon.backgroundColor = UIColor.greyOne
        }
    }
    
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
        if (paused && ruckusTimer.currentMode == .working) {
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
        timeLabel.textColor = UIColor.theOrange
        modeLabel.textColor = UIColor.theOrange
        DispatchQueue.main.async {
            self.ruckusTimer.start(timestamp)
        }
        hidePlayButton()
        modeLabel.isHidden = false
    }
    
    
    @objc func stopFromWatch() { 
        DispatchQueue.main.async {
            self.stopWorkout()
        }
    }
    func stopWorkout() {
        stopCrowd()
        ruckusTimer.stop()
        showPlayButton()
        resetUI()
        paused = false
        running = false
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
        ruckusTimer.pause(timestamp)
        showPlayButton()
    }
    
    func pauseWorkoutTimer() {
        ruckusTimer.pause(nil)
        running = false
        showPlayButton()
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
    
    // interacting with buttons
    @IBAction func clickPause(_ sender: Any) {
        let pauseTime = NSDate()
        if let timer = comboTimer {
            timer.invalidate()
        }
        if (notificationBridge.sessionReachable()) {
            notificationBridge.sendMessageWithPayload(.PauseWorkoutFromApp, payload: ["pauseTime":pauseTime], callback: nil)
        } else {
            workoutSession.pause()
        }
        do {
            try self.soundPlayer.play("pause", withExtension: "wav")
        } catch let error {
            fatalError(error.localizedDescription)
        }
        pauseWorkout(pauseTime)
    }
    
    @IBAction func clickStop(_ sender: Any) {
        if let timer = comboTimer {
            timer.invalidate()
        }
        if notificationBridge.sessionReachable() {
            stopWorkout()
            notificationBridge.sendMessage(NotificationKey.StopWorkoutFromApp, callback: nil)
        } else {
            guard let workoutStartDate = workoutStoreHelper.workoutStartDate else {
                stopWorkout()
                workoutSession.stop(andSave: false)
                return
            }
            
            if Date().timeIntervalSince(workoutStartDate) > 20.0 {
                resetUI()
                
                // but still kill the crowed in this case
                stopCrowd()
                
                // just pause the timer for now, it WILL be stopped on the other screen
                pauseWorkoutTimer()
                // show the finished screen
                performSegue(withIdentifier: "workoutFinishedFromTimer", sender: nil)
            } else {
                stopWorkout()
                workoutSession.stop(andSave: false)
            }
        }
    }
    
    @IBAction func clickPlay(_ sender: Any) {
       if PurchasedState.sharedInstance.isPaid || currentReachabilityStatus == .notReachable {
            proceedWithPlayClick()
        } else {
            if interstitial == nil {
                proceedWithPlayClick()
            } else {
                if (interstitial.isReady) {
                    interstitial.present(fromRootViewController: self)
                } else {
                    proceedWithPlayClick()
                }
            }
        }
    }
    
}

