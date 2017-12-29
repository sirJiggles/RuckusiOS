//
//  ARVC.swift
//  ruckus
//
//  Created by Gareth on 22.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit

class ARVC: UIViewController, ARSCNViewDelegate, SCNSceneRendererDelegate, IntervalTimerDelegate, ListensToPlayEndEvents {
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var leftEyeScene: SCNView!
    @IBOutlet weak var rightEyeScene: SCNView!
    
    @IBOutlet weak var arSceneView: ARSCNView!
    
    @IBOutlet weak var leftEyeView: UIView!
    @IBOutlet weak var rightEyeView: UIView!
    let scene = ARScene.init(create: true, moveMode: false)
    
    let VRMode = true
    
    var gameOverlay: AROverlay?
    
    // Timer stuff
    
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
    
    required init?(coder aDecoder: NSCoder) {
        timer = IntervalTimer.sharedInstance
        notificationBridge = WatchNotificationBridge.sharedInstance
        intervalTimerSettings = IntervalTimerSettingsHelper()
        settingsAccessor = SettingsAccessor()
        
        super.init(coder: aDecoder)
        // set up the delgate for listening to sound end events
        soundPlayer.delegate = self
        // delgate for listening to timer events
        timer.delegate = self
    }
    
    // MARK: - VC Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateTimer()
        
        // ARKit shizzle
        //        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        //        arSceneView.session.run(configuration)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // overlay configuration
        gameOverlay = AROverlay(parent: self, size: self.view.frame.size)
        
        // AR version
//        arSceneView.scene = scene
//        arSceneView.allowsCameraControl = true
//        arSceneView.showsStatistics = true
        
        
        // normal verison
        arSceneView.isHidden = true
        
        if VRMode {
            setUpVRScene()
        } else {
            initSceneView(scnView)
            // render delegate
            scnView.delegate = scene
        }
        
        // if the timer is not started, start it now!
        if !running {
            proceedWithPlayClick()
        }
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - VC config
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscapeRight
        } else {
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK:- Helper functions
    func setUpVRScene() {
        
        let cornerSize = CGFloat(70)
        leftEyeView.layer.cornerRadius = cornerSize
        leftEyeView.layer.masksToBounds = true
        rightEyeView.layer.cornerRadius = cornerSize
        rightEyeView.layer.masksToBounds = true
        
        initSceneView(leftEyeScene, withDebug: true)
        initSceneView(rightEyeScene, withDebug: false)
        
        // render delegate (in here for the VR stuff)
        leftEyeScene.delegate = self
        rightEyeScene.isPlaying = true
        
        // add cam for the left eye lopez
        let cam = SCNCamera()
        cam.zNear = 0.1
        let camNode = SCNNode()
        camNode.position = SCNVector3(0, 2, 3)
        camNode.camera = cam
        leftEyeScene.scene?.rootNode.addChildNode(camNode)
        leftEyeScene.pointOfView = camNode
        
        // overlay for both scenes
        if let overlay = gameOverlay {
            leftEyeScene.overlaySKScene = overlay
            rightEyeScene.overlaySKScene = overlay
        }
    }
    
    func initSceneView(_ sceneView: SCNView, withDebug debug: Bool = false) {
        sceneView.scene = scene
        
        // gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        sceneView.addGestureRecognizer(tapGesture)
        
        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = debug
        
        // configure the view
        sceneView.backgroundColor = UIColor.black
    }
    
    // debug for the move to functionality
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        // what did you tap on
        let sceneView = recognizer.view as! SCNView
        let pos = recognizer.location(in: sceneView)
        
        scene.follow(position: SCNVector3(pos.x, pos.y, 0))
    }
    
    
    // MARK: - render delegate for VR mode scene
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFrame()
            // call redraw on scene for agents etc
            self.scene.update(updateAtTime: time)
        }
    }
    
    func updateFrame() {
        
        // Clone pointOfView for Second View
        let pointOfView : SCNNode = (leftEyeScene.pointOfView?.clone())!
        
        // Determine Adjusted Position for Right Eye
        let orientation : SCNQuaternion = pointOfView.orientation
        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let eyePos : GLKVector3 = GLKVector3Make(1.0, 0.0, 0.0)
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        
        let mag : Float = 0.066 // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
        pointOfView.position.x += rotatedEyePosSCNV.x * mag
        pointOfView.position.y += rotatedEyePosSCNV.y * mag
        pointOfView.position.z += rotatedEyePosSCNV.z * mag
        
        // Set PointOfView for SecondView
        rightEyeScene.pointOfView = pointOfView
        
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
        
        comboTimer = Timer.scheduledTimer(timeInterval: comboPauseTime, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
    }
    
    
    // MARK: - Delegate functions for Ruckus timer
    func didTickSecond(time: String, mode: TimerMode) {
        gameOverlay?.timeLabel.text = time
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
    
    func tick(newValue: Double) -> Void {
        // update the ring, always
        // @TODO might not even need this!
    }
    
    func updateCircuitNumber(to newValue: Double, circuitNumber: Int) {
        let roundNum = circuitNumber - 1
        gameOverlay?.roundLabel.text = "Round: \(roundNum)"
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
        resetUI()
    }
    
    func aboutToSwitchModes() {
        // used so we know not to keep calling out combos
        aboutToSwitch = true
    }
    
    func setUpSwitchModes() {
        gameOverlay?.timeLabel.text = "00:00"
        switch (timer.currentMode) {
        case .preparing:
            gameOverlay?.modeLabel.text = "Prepare"
            workoutSession.pause()
        case .resting:
            gameOverlay?.modeLabel.text = "Resting"
            workoutSession.pause()
        case .stretching:
            gameOverlay?.modeLabel.text = "Stretch"
            workoutSession.pause()
        case .warmup:
            workoutSession.resume()
            gameOverlay?.modeLabel.text = "Warmup"
        case .working:
            workoutSession.resume()
            
            if callOutsEnabled {
                
                if (comboTimer != nil) {
                    comboTimer?.invalidate()
                }
                // start the combo calling after a second
                comboTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(runComboAfterTime), userInfo: nil, repeats: false)
            }
            
            gameOverlay?.modeLabel.text = "Working"
        }
        
    }
    
    func setColours() {
        switch (timer.currentMode) {
        case .preparing:
            gameOverlay?.modeLabel.color = UIColor.lightGreen
            gameOverlay?.timeLabel.color = UIColor.lightGreen
        case .resting, .stretching:
            gameOverlay?.modeLabel.color = UIColor.lightestBlue
            gameOverlay?.timeLabel.color = UIColor.lightestBlue
        case .working, .warmup:
            gameOverlay?.modeLabel.color = UIColor.theOrange
            gameOverlay?.timeLabel.color = UIColor.theOrange
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
        
        
        setColours()
        setUpSwitchModes()
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
    
    func resetUI() {
        gameOverlay?.timeLabel.text = "00:00"
        gameOverlay?.timeLabel.color = UIColor.white
        gameOverlay?.modeLabel.isHidden = true
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
        gameOverlay?.timeLabel.color = UIColor.theOrange
        gameOverlay?.modeLabel.color = UIColor.theOrange
        DispatchQueue.main.async {
            self.timer.start(timestamp)
        }
        gameOverlay?.modeLabel.isHidden = false
    }
    
    
    @objc func stopFromWatch() {
        DispatchQueue.main.async {
            self.stopWorkout()
        }
    }
    func stopWorkout() {
        stopCrowd()
        timer.stop()
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
        timer.pause(timestamp)
    }
    
    func pauseWorkoutTimer() {
        timer.pause(nil)
        running = false
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

}
