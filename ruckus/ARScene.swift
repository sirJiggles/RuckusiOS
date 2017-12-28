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
    var modelWrapper = SCNNode()
    
    // this is all for the seeking behaviour, we won't use it for now
    var playerNode = SCNNode()
    var timeLast: Double?
    var player: PlayerEntity?
    var fighter: FighterEntity?
    
    lazy var componentSystems:[GKComponentSystem] = {
        let targetSystem = GKComponentSystem(componentClass: TargetingAgent.self)
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let nodeSystem = GKComponentSystem(componentClass: NodeComponent.self)
        return [targetSystem, moveSystem, nodeSystem]
    }()
    
    convenience init(create: Bool) {
        self.init()
        
        // load the char dae
        let charModel = SCNScene(named: "art.scnassets/char.dae")
        if let charUnwrapped = charModel {
            
            // we need to do this as mixamo puts all on root level
            for child in charUnwrapped.rootNode.childNodes {
                model.addChildNode(child)
            }
            
            // 'face' the correct direction, for the look at
            model.rotation = SCNVector4(0, 1, 0, Float(180).degreesToRadians)
            
            // wrapper for scaling, and used later for following
            modelWrapper.addChildNode(model)
            modelWrapper.scale = SCNVector3(0.01,0.01,0.01)

            rootNode.addChildNode(modelWrapper)
            
        }
        
        lightsCameraAction()
        
        createSeekingBehaviour()
        
        // start callin the hits
        let _ = ARAnimationController.init(withModel: model)
    }
    
    // this is called when we touch the scene, it's a simple test func
    func follow(position: SCNVector3) {
        // @MAKE go to position soon
//        playerNode.position = position
        
        // move it arround my char
        playerNode.position = SCNVector3(Int(arc4random_uniform(4) + 1),0, Int(arc4random_uniform(4) + 1))
    }
    
    // set up the lights and cam
    func lightsCameraAction() {
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        if let cam = cameraNode.camera {
////            cam.usesOrthographicProjection = true
////            cam.zFar = 10000
////            cam.zNear = 0.001
//        }
//        cameraNode.position = SCNVector3(0, 4, 2)
        
        // root node always accessible as we are subclassing scnscene
//        rootNode.addChildNode(cameraNode)
        
        
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
//
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        if let amLight = ambientLightNode.light {
            amLight.type = .ambient
            amLight.color = UIColor.white
            amLight.intensity = 200
        }
        rootNode.addChildNode(ambientLightNode)
        
        // node to look at (head of the bot)
//        if let spotLookAtNode = model.childNode(withName: "mixamorig_Head", recursively: true) {
//
//            spotLookAtNode.position = SCNVector3Zero
//
//            // look at look at node
//            spotLightNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
//            cameraNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
//        }
        
        let centerNode = SCNNode()
        centerNode.position = SCNVector3Zero
        rootNode.addChildNode(centerNode)
        spotLightNode.constraints = [SCNLookAtConstraint(target: centerNode)]
        
    }
    
    func createSeekingBehaviour() {
        
        let box2 = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.1)
        box2.firstMaterial?.diffuse.contents = UIColor.green
        playerNode.geometry = box2
        playerNode.position = SCNVector3(4,0,0)
        
        rootNode.addChildNode(playerNode)
        
        player = PlayerEntity.init(usingNode: playerNode)
        
        fighter = FighterEntity.init(withTargetAgent: player!.agent, andNode: modelWrapper
        )
        
        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: player!)
            componentSystem.addComponent(foundIn: fighter!)
        }
        
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
        
        // update the agents
        if let pl = player {
            if let component = pl.component(ofType: NodeComponent.self) {
                modelWrapper.look(at: component.node.position)
            }
            pl.agent.update(deltaTime: dt)
        }
        
        fighter?.agent.update(deltaTime: dt)
        
        
//        for componentSystem in componentSystems {
//            componentSystem.update(deltaTime: dt)
//        }
        
        timeLast = time
        
    }
}


