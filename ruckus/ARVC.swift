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

protocol PunchInTheHeadDelegate {
    func didGetPunched() -> Void
    var canBeHit: Bool {
        get set
    }
}

class ARVC: TimableController, TimableVCDelegate, ARSCNViewDelegate, SCNSceneRendererDelegate, PunchInTheHeadDelegate {
    
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var leftEyeScene: SCNView!
    @IBOutlet weak var rightEyeScene: SCNView!
    
    @IBOutlet weak var leftEyeSceneAR: ARSCNView!
    @IBOutlet weak var rightEyeSceneAR: ARSCNView!
    
    @IBOutlet weak var leftEyeView: UIView!
    @IBOutlet weak var rightEyeView: UIView!
    
    let scene = ARScene.init(create: true)
    
    var gameOverlay: AROverlay?
    var punchCount: Int = 0
    var canBeHit: Bool = true
    
    let ARMode = false
    
    // this changes depending on AR mode
    var leftScene: SCNView?
    var rightScene: SCNView?
    
    var playOnLoad = true

    // how long the user is untouchable, gets set based on difficulty
    var invincibleTime = 0.08
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        
        if let difficulty = self.settingsAccessor?.getARDifficulty() {
            if difficulty > 0 {
                invincibleTime = Double(0.08 / difficulty)
            } else {
                invincibleTime = 0.08
            }
        }
        
        // we want to know about VC timer stuff
        timerVCDelegate = self
    }
    
    // MARK: - VC Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARMode {
            let configuration = ARWorldTrackingConfiguration()
            if let left = leftEyeScene as? ARSCNView {
                left.session.run(configuration)
            }
        }
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ARMode {
            leftScene = leftEyeSceneAR
            rightScene = rightEyeSceneAR
            
            leftEyeScene.isHidden = true
            rightEyeScene.isHidden = true
        } else {
            leftEyeSceneAR.isHidden = true
            rightEyeSceneAR.isHidden = true
            
            leftScene = leftEyeScene
            rightScene = rightEyeScene
        }
        
        // overlay configuration
        gameOverlay = AROverlay(parent: self, size: self.view.frame.size)
        
        setUpVRScene()
        
        // delegate for sending punch signals
        scene.punchDelegate = self
        
        // if the timer is not started, start it now! (like a button click)
        if !running && playOnLoad {
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
        
        initSceneView(leftScene!, withDebug: true)
        initSceneView(rightScene!, withDebug: false)
        
        // render delegate (in here for the VR stuff)
        leftScene?.delegate = self
        rightScene?.isPlaying = true
        
        leftScene?.debugOptions = [
//            SCNDebugOptions.showPhysicsShapes,
//            SCNDebugOptions.showBoundingBoxes
        ]
        
        // allows the user to manipulate the camera
        leftScene?.allowsCameraControl = true
        
        // add cam for the left eye lopez
        let cam = SCNCamera()
        cam.zNear = 0.1
        let camNode = SCNNode()
        camNode.position = SCNVector3(0, 2, 3)
        camNode.camera = cam
        leftScene?.scene?.rootNode.addChildNode(camNode)
        leftScene?.pointOfView = camNode
        
        // overlay for both scenes
        if let overlay = gameOverlay {
            leftScene?.overlaySKScene = overlay
            rightScene?.overlaySKScene = overlay
        }
    }
    
    func initSceneView(_ sceneView: SCNView, withDebug debug: Bool = false) {
        sceneView.scene = scene
        
        // gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        sceneView.addGestureRecognizer(tapGesture)
        
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
    
    // MARK: - Punch in the head delegates
    func didGetPunched() {
        canBeHit = false
        punchCount = punchCount + 1
        gameOverlay?.punchLabel.text = ("Hits: \(punchCount)")
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: self.invincibleTime, repeats: false){ _ in
                self.canBeHit = true
            }
        }
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
        let pointOfView : SCNNode = (leftScene?.pointOfView?.clone())!
        
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
        gameOverlay?.timeLabel.fontColor = UIColor.white
        gameOverlay?.modeLabel.isHidden = true
    }
    
    func setColours() {
        switch (timer.currentMode) {
        case .preparing:
            gameOverlay?.modeLabel.fontColor = UIColor.lightGreen
            gameOverlay?.timeLabel.fontColor = UIColor.lightGreen
        case .resting, .stretching:
            gameOverlay?.modeLabel.fontColor = UIColor.lightestBlue
            gameOverlay?.timeLabel.fontColor = UIColor.lightestBlue
        case .working, .warmup:
            gameOverlay?.modeLabel.fontColor = UIColor.theOrange
            gameOverlay?.timeLabel.fontColor = UIColor.theOrange
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
        gameOverlay?.roundLabel.text = "Round: \(circuitNumber)"
    }
    
    func startWorkoutUI() {
        gameOverlay?.timeLabel.fontColor = UIColor.theOrange
        gameOverlay?.modeLabel.fontColor = UIColor.theOrange
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
