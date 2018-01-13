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
import AudioToolbox

protocol PunchInTheHeadDelegate {
    func didGetPunched() -> Void
    var canBeHit: Bool {
        get set
    }
}

class ARVC: UIViewController, ARSCNViewDelegate, PunchInTheHeadDelegate {
    
    
    @IBOutlet weak var fullScreenARView: ARSCNView!
    @IBOutlet weak var leftEyeSceneAR: ARSCNView!
    @IBOutlet weak var rightEyeSceneAR: ARSCNView!
    
    @IBOutlet weak var leftEyeView: UIView!
    @IBOutlet weak var rightEyeView: UIView!
    
    @IBOutlet weak var imageViewLeft: UIImageView!
    @IBOutlet weak var imageViewRight: UIImageView!
    
    @IBOutlet weak var rotateInstructionsView: UIView!
    
    @IBOutlet weak var rightEyeCountdown: UILabel!
    
    @IBOutlet weak var leftEyeCountdown: UILabel!
    
    let scene = ARScene.init(create: true)
    
    var punchCount: Int = 0
    var canBeHit: Bool = true

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
    
    let eyeCamera : SCNCamera = SCNCamera()
    
    var settingsAccessor: SettingsAccessor?
    
    // Parametres
    let interpupilaryDistance = 0.066 // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
    let viewBackgroundColor : UIColor = UIColor.black
    
    // Set eyeFOV and cameraImageScale. Uncomment any of the below lines to change FOV.
    //    let eyeFOV = 38.5; let cameraImageScale = 1.739; // (FOV: 38.5 ± 2.0) Brute-force estimate based on iPhone7+
    let eyeFOV = 60; let cameraImageScale = 3.478; // Calculation based on iPhone7+ // <- Works ok for cheap mobile headsets. Rough guestimate.
    //    let eyeFOV = 90; let cameraImageScale = 6; // (Scale: 6 ± 1.0) Very Rough Guestimate.
    //    let eyeFOV = 120; let cameraImageScale = 8.756; // Rough Guestimate.
    
    var rumbleTimer: Timer?
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        
        settingsAccessor = SettingsAccessor()
        
        if let difficulty = self.settingsAccessor?.getDifficulty() {
            if difficulty > 0 {
                invincibleTime = Double(0.08 / difficulty)
            } else {
                invincibleTime = 0.08
            }
        }
    }
    
    // MARK: - VC Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        fullScreenARView.session.run(configuration, options: [
            ARSession.RunOptions.removeExistingAnchors,
            ARSession.RunOptions.resetTracking
        ])
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fullScreenARView.isHidden = true
        
        setUpVRScene()
        
        // delegate for sending punch signals
        scene.punchDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // house keeping
        rumbleTimer?.invalidate()
        leftEyeCountdown.isHidden = true
        rightEyeCountdown.isHidden = true
        started = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        rotateInstructionsView.isHidden = UIDevice.current.orientation.isLandscape
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
        let hitResults = fullScreenARView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                for var index in 0...anchors.count - 1 {
                    // remove all the nodes from the scene except for the one that is selected
                    if anchors[index].identifier != planeAnchor.identifier {
                        fullScreenARView.node(for: anchors[index])?.removeFromParentNode()
                        fullScreenARView.session.remove(anchor: anchors[index])
                    }
                    index += 1
                }
                // keep track of selected anchor only
                anchors = [planeAnchor]
                // set isPlaneSelected to true
                isPlaneSelected = true
                setPlaneTexture(node: fullScreenARView.node(for: planeAnchor)!)
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
        
        let hitResults = fullScreenARView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            let newLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            
            scene.moveFloorTo(position: newLocation)
            
            scene.setCharAt(position: newLocation)
            
            fullScreenARView.node(for: result.anchor!)!.removeFromParentNode()
            fullScreenARView.session.remove(anchor: result.anchor!)
            
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
        
        fullScreenARView.scene = scene
        leftEyeSceneAR.scene = scene
        rightEyeSceneAR.scene = scene
        
        fullScreenARView.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        fullScreenARView.isHidden = true
        
//        leftEyeSceneAR.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // debug for left eye lopez
//        leftEyeSceneAR.debugOptions = [ARSCNDebugOptions.showWorldOrigin, .showConstraints]
        
        rightEyeSceneAR.isPlaying = true
        leftEyeSceneAR.isPlaying = true
        
        self.view.backgroundColor = viewBackgroundColor
        
        ////////////////////////////////////////////////////////////////
        // Create CAMERA
        eyeCamera.zNear = 0.001
        /*
         Note:
         - camera.projectionTransform was not used as it currently prevents the simplistic setting of .fieldOfView . The lack of metal, or lower-level calculations, is likely what is causing mild latency with the camera.
         - .fieldOfView may refer to .yFov or a diagonal-fov.
         - in a STEREOSCOPIC layout on iPhone7+, the fieldOfView of one eye by default, is closer to 38.5°, than the listed default of 60°
         */
        eyeCamera.fieldOfView = CGFloat(eyeFOV)
        
        ////////////////////////////////////////////////////////////////
        // Setup ImageViews - for rendering Camera Image
        self.imageViewLeft.clipsToBounds = true
        self.imageViewLeft.contentMode = UIViewContentMode.center
        self.imageViewRight.clipsToBounds = true
        self.imageViewRight.contentMode = UIViewContentMode.center
        

    }
    
    func initSceneView(_ sceneView: ARSCNView, withDebug debug: Bool = false) {
        sceneView.scene = scene
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = debug
    }
    
    func donePositioningAndStart() {
        started = true
        var seconds = 10
        // show the countdown
        leftEyeCountdown.isHidden = false
        rightEyeCountdown.isHidden = false
        
        // show the 10 second countdown and then start the fight!
        rumbleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            
            // upate the seconds countdown on the eyes
            DispatchQueue.main.async {
                self.leftEyeCountdown.text = "\(seconds)"
                self.rightEyeCountdown.text = "\(seconds)"
            }
            
            if (seconds <= 0) {
                // remove the countdown
                self.leftEyeCountdown.isHidden = true
                self.rightEyeCountdown.isHidden = true
                
                // stop the timer
                self.rumbleTimer?.invalidate()
                // now start the pain!
                self.scene.animationController?.didStart()
            }
            
            seconds -= 1
        }
        
    }
    
    // MARK: - Punch in the head delegates
    func didGetPunched() {
        canBeHit = false
        punchCount = punchCount + 1
        
        // vibrate the phone when hit!
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: self.invincibleTime, repeats: false){ _ in
                self.canBeHit = true
            }
        }
    }
    
    
    // MARK: - render delegate for VR mode scene
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // get the light estimate, and update the lights based on the room lights
        if let estimate = fullScreenARView.session.currentFrame?.lightEstimate {
            scene.spotLightNode.light?.intensity = estimate.ambientIntensity * 3
            scene.ambientLightNode.light?.intensity = estimate.ambientIntensity
        }
        DispatchQueue.main.async {
            self.updateFrame()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node:  SCNNode?
        if started {
            return node
        }
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
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
        
        // CREATE POINT OF VIEWS
        let pointOfView : SCNNode = SCNNode()
        pointOfView.transform = (fullScreenARView.pointOfView?.transform)!
        pointOfView.scale = (fullScreenARView.pointOfView?.scale)!
        // Create POV from Camera
        pointOfView.camera = eyeCamera
        
        // Set PointOfView for SceneView-LeftEye
        leftEyeSceneAR.pointOfView = pointOfView
        
        // Clone pointOfView for Right-Eye SceneView
        let pointOfView2 : SCNNode = (leftEyeSceneAR.pointOfView?.clone())!
        // Determine Adjusted Position for Right Eye
        let orientation : SCNQuaternion = pointOfView.orientation
        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let eyePos : GLKVector3 = GLKVector3Make(1.0, 0.0, 0.0)
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        let mag : Float = Float(interpupilaryDistance)
        pointOfView2.position.x += rotatedEyePosSCNV.x * mag
        pointOfView2.position.y += rotatedEyePosSCNV.y * mag
        pointOfView2.position.z += rotatedEyePosSCNV.z * mag
        
        // Set PointOfView for SceneView-RightEye
        rightEyeSceneAR.pointOfView = pointOfView2
        
        ////////////////////////////////////////////
        // RENDER CAMERA IMAGE
        /*
         Note:
         - as camera.contentsTransform doesn't appear to affect the camera-image at the current time, we are re-rendering the image.
         - for performance, this should be ideally be ported to metal
         */
        // Clear Original Camera-Image
        leftEyeSceneAR.scene.background.contents = UIColor.clear // This sets a transparent scene bg for all sceneViews - as they're all rendering the same scene.
        
        // Read Camera-Image
        let pixelBuffer : CVPixelBuffer? = fullScreenARView.session.currentFrame?.capturedImage
        if pixelBuffer == nil { return }
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer!)
        // Convert ciimage to cgimage, so uiimage can affect its orientation
        let context = CIContext(options: nil)
        let cgimage = context.createCGImage(ciimage, from: ciimage.extent)
        
        // Determine Camera-Image Scale
        var scale_custom : CGFloat = 1.0
        // let cameraImageSize : CGSize = CGSize(width: ciimage.extent.width, height: ciimage.extent.height) // 1280 x 720 on iPhone 7+
        // let eyeViewSize : CGSize = CGSize(width: self.view.bounds.width / 2, height: self.view.bounds.height) // (736/2) x 414 on iPhone 7+
        // let scale_aspectFill : CGFloat = cameraImageSize.height / eyeViewSize.height // 1.739 // fov = ~38.5 (guestimate on iPhone7+)
        // let scale_aspectFit : CGFloat = cameraImageSize.width / eyeViewSize.width // 3.478 // fov = ~60
        // scale_custom = 8.756 // (8.756) ~ appears close to 120° FOV - (guestimate on iPhone7+)
        // scale_custom = 6 // (6±1) ~ appears close-ish to 90° FOV - (guestimate on iPhone7+)
        scale_custom = CGFloat(cameraImageScale)
        
        // Determine Camera-Image Orientation
        let imageOrientation : UIImageOrientation = (UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft) ? UIImageOrientation.down : UIImageOrientation.up
        
        // Display Camera-Image
        let uiimage = UIImage(cgImage: cgimage!, scale: scale_custom, orientation: imageOrientation)
        
        self.imageViewLeft.image = uiimage
        self.imageViewRight.image = uiimage
        
        // get the position of the users head and send this to the scene
        if let cam = fullScreenARView.session.currentFrame?.camera {
            scene.updateHeadPos(withPosition: cam.transform)
        }

    }
    
    // MARK: - IBActions
    @IBAction func dismissArMode(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
