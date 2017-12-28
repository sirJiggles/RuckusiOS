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

class ARVC: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var leftEyeScene: SCNView!
    @IBOutlet weak var rightEyeScene: SCNView!
    
    @IBOutlet weak var arSceneView: ARSCNView!
    
    @IBOutlet weak var leftEyeView: UIView!
    @IBOutlet weak var rightEyeView: UIView!
    let scene = ARScene.init(create: true)
    
    let VRMode = true
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        }
    }
    
    func setUpVRScene() {
        initSceneView(leftEyeScene, withDebug: true)
        initSceneView(rightEyeScene, withDebug: false)
        
        // corner radius of the eyes
        let cornerSize = CGFloat(80)
        leftEyeView.layer.cornerRadius = cornerSize
        leftEyeView.layer.masksToBounds = true
        rightEyeView.layer.cornerRadius = cornerSize
        rightEyeView.layer.masksToBounds = true
        
        // set up different cams for each eye!
        // Create cameras
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: -0.5, y: 0, z: 0)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: 0.5, y: 0, z: 0)
        
        let camerasNode = SCNNode()
        camerasNode.position = SCNVector3(x: 0, y: 2, z: 3)
        camerasNode.addChildNode(leftCameraNode)
        camerasNode.addChildNode(rightCameraNode)
        
        // add the cams
        scene.rootNode.addChildNode(camerasNode)
        
        // set the pov
        leftEyeScene.pointOfView = leftCameraNode
        rightEyeScene.pointOfView = rightCameraNode
        
    }
    
    func initSceneView(_ sceneView: SCNView, withDebug debug: Bool = false) {
        sceneView.scene = scene
        // render delegate
        sceneView.delegate = scene
        
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
    
    
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        // what did you tap on
        let sceneView = recognizer.view as! SCNView
        let pos = recognizer.location(in: sceneView)
        
        scene.follow(position: SCNVector3(pos.x, pos.y, 0))
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        // ARKit shizzle
//        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
//        arSceneView.session.run(configuration)
    }
    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
