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

protocol PunchInTheHeadDelegate {
    func didGetPunched() -> Void
    var canBeHit: Bool {
        get set
    }
}
//SCNSceneRendererDelegate
class VRVC: TimableController, TimableVCDelegate, PunchInTheHeadDelegate, GVRCardboardViewDelegate {
    
    let scene = VRScene.init(create: true)
    
    var gameOverlay: VROverlay?
    var punchCount: Int = 0
    var canBeHit: Bool = true
    
    var playOnLoad = true

    // how long the user is untouchable, gets set based on difficulty
    var invincibleTime = 0.08
    
    var started = false
    
    // Cardboard shizzle
    var renderer : SceneKitVRRenderer?
    var renderLoop: RenderLoop?
    
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
        guard let cardboardView = GVRCardboardView(frame: CGRect.zero) else {
            fatalError("Could not cerate cardboard view")
        }
        cardboardView.delegate = self
        
//        Simulators freak
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            cardboardView.vrModeEnabled = false
        #else
            cardboardView.vrModeEnabled = true
        #endif
        cardboardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view = cardboardView
    }
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
 
//         overlay configuration
        gameOverlay = VROverlay(parent: self, size: self.view.frame.size)
        
//         just start for now!
//        donePositioningAndStart()
        
//         delegate for sending punch signals
        scene.punchDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let cardboardView = self.view as? GVRCardboardView else {
            fatalError("view is not GVRCardboardView")
        }
        
        renderLoop = RenderLoop.init(renderTarget: cardboardView,
                                     selector: #selector(GVRCardboardView.render))
        
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
    
//    func donePositioningAndStart() {
////         if the timer is not started, start it now! (like a button click)
//        if !running && playOnLoad {
//            proceedWithPlayClick()
//
//            started = true
//
//            // overlay for both eyes
//            if let overlay = gameOverlay {
////                sceneView.overlaySKScene = overlay
//            }
//        }
//    }

    // debug for the move to functionality
//    @objc func tapped(recognizer: UITapGestureRecognizer) {
//        // what did you tap on
//        let sceneView = recognizer.view as! SCNView
//        let pos = recognizer.location(in: sceneView)
//
////        scene.follow(position: SCNVector3(pos.x, pos.y, 0))
//    }

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
    
    
//     MARK: - render delegate for VR mode scene
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        DispatchQueue.main.async {
//            // call redraw on scene for agents etc
//            self.scene.update(updateAtTime: time)
//        }
//    }
    
//     MARK: - delegate functions for the timable VC!
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
    
    // MARK: - Google Cardboard hookup
    func cardboardView(_ cardboardView: GVRCardboardView!, willStartDrawing headTransform: GVRHeadTransform!) {
        renderer = SceneKitVRRenderer(scene:scene)
        
        renderer?.cardboardView(cardboardView, willStartDrawing: headTransform)
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, prepareDrawFrame headTransform: GVRHeadTransform!) {
//        renderer?.prepareFrame(with: headTransform)
        renderer?.cardboardView(cardboardView, prepareDrawFrame: headTransform)
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, draw eye: GVREye, with headTransform: GVRHeadTransform!) {
        renderer?.cardboardView(cardboardView, draw: eye, with: headTransform);
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, shouldPauseDrawing pause: Bool) {
        renderLoop?.paused = pause;
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, didFire event: GVRUserEvent) {
        
//        if event == GVRUserEvent.trigger {
//            vrController!.eventTriggered();
//        }
    }

}
