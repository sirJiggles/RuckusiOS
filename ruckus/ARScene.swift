//
//  ARScene.swift
//  ruckus
//
//  Created by Gareth on 25.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

//
//  GameScene.swift
//  deer
//
//  Created by Gareth on 19.09.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import GameKit

typealias AnimatedMove = [String:SCNAnimationPlayer]

class ARScene: SCNScene {
    var model = SCNNode()
    
    convenience init(create: Bool) {
        self.init()
        
        // load the first model state
        let idle = SCNScene(named: "art.scnassets/char.dae")
        if let indleUnwrapped = idle {
            
            for child in indleUnwrapped.rootNode.childNodes {
                model.addChildNode(child)
            }
            
            
            // wrapper for scaling
            let nodeWrapper = SCNNode()
            nodeWrapper.scale = SCNVector3(0.01,0.01,0.01)
            nodeWrapper.position = SCNVector3(0, -1, 0)
//            nodeWrapper.rotation = SCNVector4(1, 2, 0, Float(90).degreesToRadians)
            nodeWrapper.addChildNode(model)
            rootNode.addChildNode(nodeWrapper)
            
        }
        
        lightsCameraAction()
        
        // start callin those babies
        let _ = ARAnimationController.init(withModel: model)
        
    }
    
    func follow(node: SCNNode) {
        let player = PlayerEntity.init(usingNode: node)
        
        guard let moveAgent = player.component(ofType: MoveComponent.self) else {
            return
        }

//        playerAgent.delegate = player.component(ofType: MoveComponent.self)
        
       _ = FighterEntity.init(withTargetAgent: moveAgent, andNode: model)
        
        node.position = SCNVector3(0, 3, 0)
    }
    
    func lightsCameraAction() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        if let cam = cameraNode.camera {
            cam.usesOrthographicProjection = true
        }
        cameraNode.position = SCNVector3(0, 0.5, 2)
        
        // root node always accessible as we are subclassing scnscene
        rootNode.addChildNode(cameraNode)
        
        
        // lights
        let spotLightNode = SCNNode()
        spotLightNode.light = SCNLight()
        if let light = spotLightNode.light {
            light.type = .spot
            light.attenuationEndDistance = 100
            light.attenuationStartDistance = 0
            light.attenuationFalloffExponent = 1
            light.color = UIColor.white
            light.intensity = 1800
        }
        
        spotLightNode.position = SCNVector3(0,10,10)
        rootNode.addChildNode(spotLightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        if let amLight = ambientLightNode.light {
            amLight.type = .ambient
            amLight.color = UIColor.white
            amLight.intensity = 200
        }
        rootNode.addChildNode(ambientLightNode)
        
        // DEBUG CUBE
//        let cube = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
//        cube.firstMaterial?.diffuse.contents = UIColor.red
//        let box = SCNNode(geometry: cube)
//
//        box.position = SCNVector3Zero
//
//        rootNode.addChildNode(box)
        
        // node to look at (head of the bot)
        if let spotLookAtNode = model.childNode(withName: "mixamorig_Head", recursively: true) {
        
            spotLookAtNode.position = SCNVector3Zero
        
            // look at look at node
            spotLightNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
            cameraNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
        }
        
    }
}


