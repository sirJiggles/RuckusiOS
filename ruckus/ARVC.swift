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

class ARVC: TimableController, TimableVCDelegate, ARSCNViewDelegate, PunchInTheHeadDelegate {
    
    
    @IBOutlet weak var fullScreenARView: ARSCNView!
    @IBOutlet weak var leftEyeSceneAR: ARSCNView!
    @IBOutlet weak var rightEyeSceneAR: ARSCNView!
    
    @IBOutlet weak var leftEyeView: UIView!
    @IBOutlet weak var rightEyeView: UIView!
    
    
    let scene = ARScene.init(create: true)
    
    var gameOverlay: AROverlay?
    var punchCount: Int = 0
    var canBeHit: Bool = true
    
    var playOnLoad = true

    // how long the user is untouchable, gets set based on difficulty
    var invincibleTime = 0.08
    
    // plane detection and so on
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    // keep track of number of anchor nodes that are added into the scene
    var planeNodesCount = 0
    let planeHeight: CGFloat = 0.01
    // set isPlaneSelected to true when user taps on the anchor plane to select.
    var isPlaneSelected = false
    
    var started = false
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        
        if let difficulty = self.settingsAccessor?.getDifficulty() {
            if difficulty > 0 {
                invincibleTime = Double(0.08 / difficulty)
            } else {
                invincibleTime = 0.08
            }
        }
        
        // we want to know about VC timer stuff
        timerVCDelegate = self
        
        isARVC = true
    }
    
    // MARK: - VC Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        leftEyeSceneAR.session.run(configuration, options: [
            ARSession.RunOptions.removeExistingAnchors,
            ARSession.RunOptions.resetTracking
        ])
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        leftEyeView.isHidden = true
//        leftEyeSceneAR.isHidden = true
//        rightEyeSceneAR.isHidden = true
//        rightEyeView.isHidden = true
        fullScreenARView.isHidden = true
        
        // overlay configuration
        gameOverlay = AROverlay(parent: self, size: self.view.frame.size)
        
        setUpVRScene()
        
        // delegate for sending punch signals
        scene.punchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if started {
            return
        }
        guard let touch = touches.first else { return }
        let location = touch.location(in: leftEyeSceneAR)
        if !isPlaneSelected {
            selectExistingPlane(location: location)
        } else {
            addNodeAtLocation(location: location)
        }
    }
    
    // selects the anchor at the specified location and removes all other unused anchors
    func selectExistingPlane(location: CGPoint) {
        if started {
            return
        }
        // Hit test result from intersecting with an existing plane anchor, taking into account the plane’s extent.
        let hitResults = leftEyeSceneAR.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                for var index in 0...anchors.count - 1 {
                    // remove all the nodes from the scene except for the one that is selected
                    if anchors[index].identifier != planeAnchor.identifier {
                        leftEyeSceneAR.node(for: anchors[index])?.removeFromParentNode()
                        leftEyeSceneAR.session.remove(anchor: anchors[index])
                    }
                    index += 1
                }
                // keep track of selected anchor only
                anchors = [planeAnchor]
                // set isPlaneSelected to true
                isPlaneSelected = true
                setPlaneTexture(node: leftEyeSceneAR.node(for: planeAnchor)!)
            }
        }
    }
    
    func setPlaneTexture(node: SCNNode) {
        if started {
            return
        }
        if let geometryNode = node.childNodes.first {
            if node.childNodes.count > 0 {
                geometryNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "overlay_grid")
                geometryNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
                geometryNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
                geometryNode.geometry?.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
                geometryNode.geometry?.firstMaterial?.diffuse.mipFilter = SCNFilterMode.linear
            }
        }
    }
    
    func addNodeAtLocation(location: CGPoint) {
        guard anchors.count > 0 else {
            print("anchors are not created yet")
            return
        }
        
        if started {
            return
        }
        
        let hitResults = leftEyeSceneAR.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            let newLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            
            scene.setCharAt(position: newLocation)
            
            donePositioningAndStart()
        }
    }
    
    // MARK:- Helper functions
    func setUpVRScene() {
        
        let cornerSize = CGFloat(70)
        leftEyeView.layer.cornerRadius = cornerSize
        leftEyeView.layer.masksToBounds = true
        rightEyeView.layer.cornerRadius = cornerSize
        rightEyeView.layer.masksToBounds = true
        
//        fullScreenARView.scene = scene
        leftEyeSceneAR.scene = scene
        rightEyeSceneAR.scene = scene
        
        // render delegate (in here for the VR stuff)
        leftEyeSceneAR.delegate = self
        
        rightEyeSceneAR.isPlaying = true
        
        leftEyeSceneAR.automaticallyUpdatesLighting = true
        
//        leftEyeSceneAR.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    func initSceneView(_ sceneView: ARSCNView, withDebug debug: Bool = false) {
        sceneView.scene = scene
        
//        // gesture recognizer
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
//
//        sceneView.addGestureRecognizer(tapGesture)
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = debug
    }
    
    func donePositioningAndStart() {
        // if the timer is not started, start it now! (like a button click)
        if !running && playOnLoad {
            proceedWithPlayClick()
            
            started = true
            
            // overlay for both eyes
            if let overlay = gameOverlay {
                leftEyeSceneAR.overlaySKScene = overlay
                rightEyeSceneAR.overlaySKScene = overlay
            }
        }
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
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node:  SCNNode?
        if started {
            return node
        }
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
//            let geo = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let geo = SCNPlane(width: 1, height: 1)
            geo.firstMaterial?.diffuse.contents = UIColor.green
            let planeNode = SCNNode(geometry: geo)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0);
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
            
        } else {
            // haven't encountered this scenario yet
            print("not plane anchor \(anchor)")
        }
        return node
    }
    
    // Called when a new node has been mapped to the given anchor
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if started {
            return
        }
        planeNodesCount += 1
        if node.childNodes.count > 0 && planeNodesCount % 2 == 0 {
            node.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        }
    }
    
    // Called when a node has been updated with data from the given anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if started {
            return
        }
        // update the anchor node size only if the plane is not already selected.
        guard !isPlaneSelected else {
            return
        }
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
                    if let plane = planeNode.geometry as? SCNBox {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.length = CGFloat(planeAnchor.extent.z)
                        plane.height = planeHeight
                    }
                }
            }
        }
    }
    
    func updateFrame() {
        
        // Clone pointOfView for Second View
        let pointOfView : SCNNode = (leftEyeSceneAR.pointOfView?.clone())!

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
        rightEyeSceneAR.pointOfView = pointOfView

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
            scene.animationController?.didStop()
        case .resting:
            gameOverlay?.modeLabel.text = "Resting"
            scene.animationController?.didStop()
        case .stretching:
            gameOverlay?.modeLabel.text = "Stretch"
            scene.animationController?.didStop()
        case .warmup:
            gameOverlay?.modeLabel.text = "Warmup"
            scene.animationController?.didStop()
        case .working:
            gameOverlay?.modeLabel.text = "Working"
            scene.animationController?.didStart()
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
    
    func didFinishPlayingCombo() {
        // let the scene know to play a combo, only if call outs is enabled!
        scene.animationController?.didFinnishCallingCombo()
    }
    
    func tick(newValue: Double) {
        // do nothing
    }
    
    func settingsSyncUI() {
        // do nothing
    }
    
    func finnishedUI() {
        scene.animationController?.didStop()
    }
    
    func didStartUI() {
        // do nothing
    }
    
    func stopWorkoutUI() {
        scene.animationController?.didStop()
    }
    
    func pauseWorkoutUI() {
        scene.animationController?.didStop()
    }

}
