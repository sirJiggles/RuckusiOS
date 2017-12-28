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

class ARScene: SCNScene, SCNSceneRendererDelegate {
    var model = SCNNode()
    var playerNode: SCNNode?
    var timeLast: Double?
    var player: PlayerEntity?
    var fighter: FighterEntity?
    
    lazy var componentSystems:[GKComponentSystem] = {
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let nodeSystem = GKComponentSystem(componentClass: NodeComponent.self)
        return [moveSystem, nodeSystem]
    }()
    
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
//        let _ = ARAnimationController.init(withModel: model)
    }
    
    func follow(position: SCNVector3) {
        // @MAKE go to position soon
        if let node = playerNode {
            node.position = SCNVector3(0,Int(arc4random_uniform(6) + 1),Int(arc4random_uniform(6) + 1))
            
        }
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
        
        // node to look at (head of the bot)
        if let spotLookAtNode = model.childNode(withName: "mixamorig_Head", recursively: true) {
        
            spotLookAtNode.position = SCNVector3Zero
        
            // look at look at node
            spotLightNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
            cameraNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
        }
        
        let box = SCNBox(width: 1.2, height: 1.2, length: 1.2, chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        let cube = SCNNode(geometry: box)
        
        
        let box2 = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        box2.firstMaterial?.diffuse.contents = UIColor.green
        playerNode = SCNNode(geometry: box2)
        
        player = PlayerEntity.init(usingNode: playerNode!)
        
        fighter = FighterEntity.init(withTargetAgent: player!.agent, andNode: cube)
        
        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: player!)
            componentSystem.addComponent(foundIn: fighter!)
        }
        
        rootNode.addChildNode(playerNode!)
        rootNode.addChildNode(cube)
        
    }
    
    // MARK:- Render delegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // update the component systems in the scene on render
        // this is game loop!
        let dt: Double
        
        if let lt = timeLast {
            dt = time - lt
        } else {
            dt = 0
        }
        
        player?.agent.update(deltaTime: dt)
        fighter?.agent.update(deltaTime: dt)
        
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: dt)
        }
        
        
        
        timeLast = time
        
    }
}


