//
//  ARScene.swift
//  ruckus
//
//  Created by Gareth on 25.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import QuartzCore
import SceneKit
import GameKit

// collision categories for interactions between fighter and player
enum CollisionCategory : Int {
    case player = 1
    case fighter
}

enum AnimationModelName: String {
    case robot
    case futureMan
    case vanguard
    case heraklios
}

class ARScene: SCNScene, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
    var model = SCNNode()
    var modelWrapper = SCNNode()
    
    // this is all for the seeking behaviour, we won't use it for now
    var playerNode = SCNNode()
    var timeLast: Double?
    var player: PlayerEntity?
    var fighter: FighterEntity?
    
    var punchDelegate: PunchInTheHeadDelegate?
    let hitBoxHeight = 4
    
    var modelName: AnimationModelName = .robot
    var settingsAccessor: SettingsAccessor?
    // if the cam follows the user
    var moveMode: Bool = true
    
    lazy var componentSystems:[GKComponentSystem] = {
        let targetSystem = GKComponentSystem(componentClass: TargetingAgent.self)
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let nodeSystem = GKComponentSystem(componentClass: NodeComponent.self)
        return [targetSystem, moveSystem, nodeSystem]
    }()
    
    
    convenience init(create: Bool) {
        self.init()
        
        settingsAccessor = SettingsAccessor()
        
        if let animationName = settingsAccessor?.getModelName() {
            if let enumValue = AnimationModelName.init(rawValue: animationName) {
                self.modelName = enumValue
            }
        }
        
        if let moveEnabled = settingsAccessor?.getMoveMode() {
            moveMode = moveEnabled
        }
        
        // this class will check for collisions
        physicsWorld.contactDelegate = self
        
        createPlayerNode()
        
        setUpChar()
        
        makeFloor()
        
        ligntMeUp()
        
        if moveMode {
            createSeekingBehaviour()
        }
        
        // start callin the hits
        let _ = ARAnimationController.init(withModel: model)
    }
    
    // this is called when we touch the scene, it's a simple test func
    func follow(position: SCNVector3) {
        // move it arround my char
        playerNode.position = SCNVector3(Float(arc4random_uniform(2) + 1),0, Float(arc4random_uniform(2) + 1))
    }
    
    func setUpChar() {
        // load the char dae
        let charModel = SCNScene(named: "art.scnassets/\(modelName.rawValue).dae")
        if let charUnwrapped = charModel {
            
            // we need to do this as mixamo puts all on root level
            for child in charUnwrapped.rootNode.childNodes {
                model.addChildNode(child)
            }
            
            if moveMode {
//                 'face' the correct direction, for the look at
                model.rotation = SCNVector4(0, 1, 0, Float(180).degreesToRadians)
            }
            
            model.scale = SCNVector3(0.01, 0.01, 0.01)
            
            // add some levels of detail for the main char to bring the size down
            var levelsOfDetail: [SCNLevelOfDetail] = []
            
            let charNode = rootNode.childNode(withName: "Alpha_Surface", recursively: true)
            
            for index in 0 ... 5 {
                if let geo = charNode?.geometry {
                    let detailLevel = SCNLevelOfDetail(geometry: geo, worldSpaceDistance: CGFloat(index - 1))
                    levelsOfDetail.append(detailLevel)
                }
            }
            
            if let geo = charNode?.geometry {
                geo.levelsOfDetail = levelsOfDetail
            }
            
            // add collision detection to the hand nodes, these are ones we will add!
            
            let handBoxSize = CGFloat(0.1)
            let leftGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            let rightGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            
            let leftHandNode = SCNNode(geometry: leftGeo)
            let rightHandNode = SCNNode(geometry: rightGeo)
            
            if let lh = model.childNode(withName: "mixamorig_LeftHandMiddle1", recursively: true), let rh = model.childNode(withName: "mixamorig_RightHandMiddle1", recursively: true) {
                lh.addChildNode(leftHandNode)
                rh.addChildNode(rightHandNode)
            }
            
            // add collision detection to the boxes on the hands
            leftHandNode.physicsBody = SCNPhysicsBody.kinematic()
            rightHandNode.physicsBody = SCNPhysicsBody.kinematic()
            
            if let leftPhysBod = leftHandNode.physicsBody, let rightPhysBod = rightHandNode.physicsBody {
                leftPhysBod.categoryBitMask = CollisionCategory.fighter.rawValue
                leftPhysBod.contactTestBitMask = CollisionCategory.player.rawValue
                rightPhysBod.categoryBitMask = CollisionCategory.fighter.rawValue
                rightPhysBod.contactTestBitMask = CollisionCategory.player.rawValue
            }
            
            // wrapper for scaling, and used later for following
            modelWrapper.addChildNode(model)
            
            
            // get up close and personal!
            if !moveMode {
                modelWrapper.position = SCNVector3(0.1, 0.6, 2)
            }
            
            rootNode.addChildNode(modelWrapper)
            
        }
    }
    
    // set up the lights
    func ligntMeUp() {
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
      
        let centerNode = SCNNode()
        centerNode.position = SCNVector3Zero
        rootNode.addChildNode(centerNode)
        spotLightNode.constraints = [SCNLookAtConstraint(target: centerNode)]
        
    }
    
    
    func createSeekingBehaviour() {
        
        player = PlayerEntity.init(usingNode: playerNode)
        
        fighter = FighterEntity.init(withTargetAgent: player!.agent, andNode: modelWrapper
        )
        
        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: player!)
            componentSystem.addComponent(foundIn: fighter!)
        }
    }

    
    func makeFloor() {
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIColor.lightestBlue
        floor.reflectivity = 0.4
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.physicsBody = SCNPhysicsBody.static()
        
        rootNode.addChildNode(floorNode)
    }
    
    func createPlayerNode() {
        // this is the "piller" that represents where the player stands
        playerNode.position = SCNVector3(2,0,2)
        
        // add a box inside this piller, this is the one that represents the users head
        let headGeo = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let headNode = SCNNode(geometry: headGeo)
        playerNode.addChildNode(headNode)
        headNode.position = SCNVector3(0, 1.4, 0)
        
        headNode.physicsBody = SCNPhysicsBody.kinematic()
        if let physBod = headNode.physicsBody {
            physBod.categoryBitMask = CollisionCategory.player.rawValue
            physBod.contactTestBitMask = CollisionCategory.fighter.rawValue
        }
        
        rootNode.addChildNode(playerNode)
    }
    
    // MARK: - Collision detection set up and delegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let isAFighter = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.fighter.rawValue
        let isAPlayer = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.player.rawValue
        
        let isBFighter = contact.nodeB.physicsBody!.categoryBitMask == CollisionCategory.fighter.rawValue
        let isBPlayer = contact.nodeB.physicsBody!.categoryBitMask == CollisionCategory.player.rawValue
        
        if (isAPlayer && isBFighter) || (isAFighter && isBPlayer) {
            // send a message for the amount of times hit to the overlay
            if let delegate = punchDelegate {
                if delegate.canBeHit {
                    delegate.didGetPunched()
                }
            }
        }
    }
    
    // MARK:- Render delegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        update(updateAtTime: time)
    }
    
    func update(updateAtTime time: TimeInterval) {
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


