//
//  StartButtonManager.swift
//  ruckus
//
//  Created by Gareth on 13.02.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import SceneKit

protocol ManagesStartButton {
    func placeStartButton(onScene scene: ARScene) -> Void
    func startedToLookAt() -> Void
    func stoppedLooking() -> Void
}

class StartButtonManager: ManagesStartButton {
    
    var progressBar = SCNBox()
    var buttonNode = SCNNode()
    let progressComplete = 0.7
    var scene: ARScene?
    var lookingTimer = Timer()
    var justStarted = false
    
    func placeStartButton(onScene scene: ARScene) -> Void {
        let startGeo = SCNBox(width: 0.1, height: 0.4, length: 0.8, chamferRadius: 0.03)
        startGeo.firstMaterial?.diffuse.contents = UIColor.lightGreen
        
        let startButton = SCNNode(geometry: startGeo)
        
        let startText = SCNText(string: "Start!", extrusionDepth: 0.02)
        startText.font = UIFont.systemFont(ofSize: 0.21)
        
        let startTextNode = SCNNode(geometry: startText)
        
        startButton.addChildNode(startTextNode)
        
        let progressGeo = SCNBox(width: 0.005, height: 0.01, length: 0, chamferRadius: 0)
        progressGeo.firstMaterial?.diffuse.contents = UIColor.white
        
        let progressNode = SCNNode(geometry: progressGeo)
        
        startButton.addChildNode(progressNode)
        
        progressNode.position = SCNVector3(-0.05,-0.13,0)
        startButton.rotation = SCNVector4(0, 1, 0, Float(270).degreesToRadians)
        startTextNode.position = SCNVector3(-0.05, -1.06, -0.3)
        startTextNode.rotation = SCNVector4(0, 1, 0, Float(270).degreesToRadians)
        
        startTextNode.castsShadow = false
        
        self.progressBar = progressGeo
        self.scene = scene
        self.buttonNode = startButton
        
        // set the name for the hit testing
        startButton.name = NodeNames.startButton.rawValue
        
        startButton.position = SCNVector3(0, (scene.usersHeight / 100) + 0.5, 0)
        
        startButton.castsShadow = false
        
        scene.modelWrapper.addChildNode(startButton)
    }
    
    func startedToLookAt() {
        var done = 0.2
        // some easy to read vars for us
        let tick: Double = 0.2
        let totalTime: Double = 4
        let oneUnit = totalTime / tick
        let percentage = progressComplete / oneUnit
        // @TODO maybe this does not need to be fired 20 times, now we have the animation
        lookingTimer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true, block: { _ in
            SCNTransaction.animationDuration = tick
            self.progressBar.length = self.progressBar.length + CGFloat(percentage)
            
            done = done + tick
            
            // if we get to 4 seconds
            if done >= totalTime {
                self.lookingTimer.invalidate()
                self.buttonNode.removeFromParentNode()
                self.scene?.start()
                self.scene?.gazeDelegate?.endGaze()
                self.justStarted = true
            }
        })
    }
    
    func stoppedLooking() {
        lookingTimer.invalidate()
        progressBar.length = 0.0
    }
    
}
