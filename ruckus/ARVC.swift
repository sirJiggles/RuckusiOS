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

class ARVC: TimableController, TimableVCDelegate, ARSCNViewDelegate, SCNSceneRendererDelegate {
    
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

//    var notificationBridge: WatchNotificationBridge
//    let intervalTimerSettings: IntervalTimerSettingsHelper
//    var comboTimer: Timer?
//
//    var soundPlayer = SoundPlayer.sharedInstance
//    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
//    let workoutSession = WorkoutSession.sharedInstance
//    var settingsAccessor: SettingsAccessor?
//
//    var paused: Bool = false
//    var wasPaused: Bool = false
//    var running: Bool = false
//    var callOutsEnabled: Bool = false
//    var comboPauseTime: Double = 1.0
//    var aboutToSwitch: Bool = false
//    var crowedSoundsEnabled: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // we want to know about VC timer stuff
        timerVCDelegate = self
    }
    
    // MARK: - VC Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        // if the timer is not started, start it now! (like a button click)
        if !running {
            proceedWithPlayClick()
        }
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
    
    // MARK: - delegate functions for the timable VC!
    func resetUI() {
        gameOverlay?.timeLabel.text = "00:00"
        gameOverlay?.timeLabel.color = UIColor.white
        gameOverlay?.modeLabel.isHidden = true
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
    
    func setUpSwitchModesUI() {
        gameOverlay?.timeLabel.text = "00:00"
        switch (timer.currentMode) {
        case .preparing:
            gameOverlay?.modeLabel.text = "Prepare"
        case .resting:
            gameOverlay?.modeLabel.text = "Resting"
        case .stretching:
            gameOverlay?.modeLabel.text = "Stretch"
        case .warmup:
            gameOverlay?.modeLabel.text = "Warmup"
        case .working:
            gameOverlay?.modeLabel.text = "Working"
        }
    }
    
    func updateCircuitNumberUI(to newValue: Double, circuitNumber: Int) {
        let roundNum = circuitNumber - 1
        gameOverlay?.roundLabel.text = "Round: \(roundNum)"
    }
    
    func startWorkoutUI() {
        gameOverlay?.timeLabel.color = UIColor.theOrange
        gameOverlay?.modeLabel.color = UIColor.theOrange
        gameOverlay?.modeLabel.isHidden = false
    }
    
    func didTickUISecond(time: String, mode: TimerMode) {
        gameOverlay?.timeLabel.text = time
    }
    
    func tick(newValue: Double) {
        // do nothing
    }
    
    func settingsSyncUI() {
        // do nothing
    }
    
    func finnishedUI() {
        // do nothing
    }
    
    func didStartUI() {
        // do nothing
    }
    
    func stopWorkoutUI() {
        // do nothing
    }
    
    func pauseWorkoutUI() {
        // do nothing
    }
    
    // MARK: - IB actions
    @IBAction func doubleTapThat(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
