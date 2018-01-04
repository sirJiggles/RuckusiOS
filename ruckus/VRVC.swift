//
//  VRVC.swift
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
//SCNSceneRendererDelegate
class VRVC: TimableController, TimableVCDelegate, PunchInTheHeadDelegate, GVRCardboardViewDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    
//    let scene = VRScene.init(create: true)
    
    // dummy scene for now
    let scene = SCNScene()
    
    var gameOverlay: VROverlay?
    var punchCount: Int = 0
    var canBeHit: Bool = true
    
    var playOnLoad = true

    // how long the user is untouchable, gets set based on difficulty
    var invincibleTime = 0.08
    
    var started = false
    
    // Cardboard shizzle
    var renderer : [SCNRenderer?] = []
    var renderTime = 0.0 // seconds
    var renderLoop: VRRenderLoop?
    
//    let VRControllerClassKey = "VRControllerClass";
//
    var vrController: VRControllerSwift?;
    
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
        
        isVRVC = true
    }
    
    override func loadView() {
//        let vrControllerClassName = Bundle.main
//            .object(forInfoDictionaryKey: VRControllerClassKey) as! String;
//
//        guard let vrClass = NSClassFromString(vrControllerClassName) as? VRControllerProtocol.Type else {
//            fatalError("#fail Unable to find class \(vrControllerClassName), referenced in Info.plist, key=\(VRControllerClassKey)")
//        }
//
//        vrController = vrClass.init();
        
        vrController = VRControllerSwift.init()
        
        
        let cardboardView = GVRCardboardView(frame: CGRect.zero)
        cardboardView?.delegate = self
        cardboardView?.vrModeEnabled = true
        cardboardView?.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        
        self.view = cardboardView
    }
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
 
        // overlay configuration
        gameOverlay = VROverlay(parent: self, size: self.view.frame.size)
        
        // render delegate
//        sceneView.delegate = self
        
        // just start for now!
//        donePositioningAndStart()
        
        // delegate for sending punch signals
//        scene.punchDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let cardboardView = self.view as? GVRCardboardView else {
            fatalError("Could not get cardboard view from self")
        }
        
        renderLoop = VRRenderLoop.init(renderTarget: cardboardView, selector: #selector(GVRCardboardView.render))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        renderLoop?.invalidate()
        renderLoop = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func donePositioningAndStart() {
        // if the timer is not started, start it now! (like a button click)
        if !running && playOnLoad {
            proceedWithPlayClick()
            
            started = true
            
            // overlay for both eyes
//            if let overlay = gameOverlay {
//                sceneView.overlaySKScene = overlay
//            }
        }
    }
    
    // debug for the move to functionality
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        // what did you tap on
        let sceneView = recognizer.view as! SCNView
        let pos = recognizer.location(in: sceneView)
        
//        scene.follow(position: SCNVector3(pos.x, pos.y, 0))
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
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        DispatchQueue.main.async {
//            // call redraw on scene for agents etc
//            self.scene.update(updateAtTime: time)
//        }
//    }
    
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
//            scene.animationController?.didStop()
        case .resting:
            gameOverlay?.modeLabel.text = "Resting"
//            scene.animationController?.didStop()
        case .stretching:
            gameOverlay?.modeLabel.text = "Stretch"
//            scene.animationController?.didStop()
        case .warmup:
            gameOverlay?.modeLabel.text = "Warmup"
//            scene.animationController?.didStop()
        case .working:
            gameOverlay?.modeLabel.text = "Working"
//            scene.animationController?.didStart()
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
//        scene.animationController?.didFinnishCallingCombo()
    }
    
    func tick(newValue: Double) {
        // do nothing
    }
    
    func settingsSyncUI() {
        // do nothing
    }
    
    func finnishedUI() {
//        scene.animationController?.didStop()
    }
    
    func didStartUI() {
        // do nothing
    }
    
    func stopWorkoutUI() {
//        scene.animationController?.didStop()
    }
    
    func pauseWorkoutUI() {
//        scene.animationController?.didStop()
    }
    
    // MARK: - Google Cardboard hookup
    func createRenderer() -> SCNRenderer {
        let renderer = SCNRenderer.init(context: EAGLContext.current(), options: nil)
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        renderer.pointOfView = camNode
        renderer.scene = vrController!.scene
        // comment this out if you would like custom lighting
        renderer.autoenablesDefaultLighting = true
        return renderer
    }
    
    
    func cardboardView(_ cardboardView: GVRCardboardView!, willStartDrawing headTransform: GVRHeadTransform!) {
        renderer.append(createRenderer())
        renderer.append(createRenderer())
        renderer.append(createRenderer())
    }
    
    
    func cardboardView(_ cardboardView: GVRCardboardView!, prepareDrawFrame headTransform: GVRHeadTransform!) {
        
        vrController!.prepareFrame(with: headTransform);
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        // can't get SCNRenderer to do this, has to do myself
        if let color = scene.background.contents as? UIColor {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            
            glClearColor(GLfloat(r), GLfloat(g), GLfloat(b), 1)
        }
        else {
            glClearColor(0, 0, 0, 1)
        }
        
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));
        glEnable(GLenum(GL_SCISSOR_TEST));
        
        renderTime = CACurrentMediaTime()
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, draw eye: GVREye, with headTransform: GVRHeadTransform!) {
        
        let viewport = headTransform.viewport(for: eye);
        glViewport(GLint(viewport.origin.x), GLint(viewport.origin.y), GLint(viewport.size.width), GLint(viewport.size.height));
        glScissor(GLint(viewport.origin.x), GLint(viewport.origin.y), GLint(viewport.size.width), GLint(viewport.size.height));
        
        
        let projection_matrix = headTransform.projectionMatrix(for: eye, near: 0.1, far: 1000.0);
        let model_view_matrix = GLKMatrix4Multiply(headTransform.eye(fromHeadMatrix: eye), headTransform.headPoseInStartSpace())
        
        guard let eyeRenderer = renderer[eye.rawValue] else {
            fatalError("no eye renderer for eye")
        }
        
        eyeRenderer.pointOfView?.camera?.projectionTransform = SCNMatrix4FromGLKMatrix4(projection_matrix);
        eyeRenderer.pointOfView?.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Transpose(model_view_matrix));
        
        if glGetError() == GLenum(GL_NO_ERROR) {
            eyeRenderer.render(atTime: renderTime)
        }
        
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, shouldPauseDrawing pause: Bool) {
        renderLoop?.paused = pause;
    }

}
