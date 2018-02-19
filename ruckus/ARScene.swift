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
    case maleOne
    case maleTwo
    case maleThree
    case maleFour
    case femaleOne
    case femaleTwo
    case femaleThree
    case femaleFour
}

class ARScene: SCNScene, SCNPhysicsContactDelegate {
    var model = SCNNode()
    var modelWrapper = SCNNode()
    var ring = SCNNode()
    var ringEnabled = false
    
    var headNode = SCNNode()
    
    var punchDelegate: PunchInTheHeadDelegate?
    var gazeDelegate: GazeDelegate?
    var gameDelegate: GameDelegate?
    
    var theFloor: Float = 0
    
    var modelName: AnimationModelName = .maleOne
    var scaleOfModel: Float = 0
    
    var settingsAccessor: SettingsAccessor?
    
    var animationController: ARAnimationController?
    
    var healthManager: HealthBarManager?
    let startButtonManager = StartButtonManager()
    
    var spotLightNode = SCNNode()
    var ambientLightNode = SCNNode()
    
    var floorNode = SCNNode()
    var usersHeight: Float = 170.0
    var headYStanding: Float = 0
    
    var startPos = SCNVector3()
    
    convenience init(create: Bool) {
        self.init()
        
        settingsAccessor = SettingsAccessor()
        // this class will check for collisions
        physicsWorld.contactDelegate = self
        
        // start callin the hits
        animationController = ARAnimationController()
        
        healthManager = HealthBarManager(withScene: self)
    }
    
    // clear the scene when will leave
    func empty() {
        healthManager?.stopHealthTicking()
        animationController?.didStop(andIdle: false)
        rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        // remove all from model wrapper (might not be in scene yet)
        modelWrapper.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    func settup() {
        if let animationName = settingsAccessor?.getModelName() {
            if let enumValue = AnimationModelName.init(rawValue: animationName) {
                self.modelName = enumValue
            }
        }
        
        if let height = settingsAccessor?.getUsersHeight() {
            usersHeight = height
        }
        
        if let enabled = self.settingsAccessor?.getRingEnabled() {
            ringEnabled = enabled
        }
        
        createPlayerNode()
        
        setUpChar()
        
        setUpRing()
        
        ligntMeUp()
        
        createFloor()
        
        animationController?.prepare(withModel: model)
        animationController?.start()
        
        // fetch the settings for the health bar
        healthManager?.fetchSettings()
    }
    
    func updateHeadPos(withPosition position: matrix_float4x4) {
        // only look at if not throwing a combo, else it is too hard to move
        // out the way
        if let animationController = self.animationController {
            if !animationController.hitting {
                // where should we look
                let posForLookAt = SCNVector3(
                    position.columns.3.x,
                    theFloor,
                    position.columns.3.z
                )
                modelWrapper.look(at: posForLookAt)
            }
            
            // if users just started, get the yPos now, this is the standing y
            if (startButtonManager.justStarted) {
                headYStanding = position.columns.3.y
                startButtonManager.justStarted = false
            }
            
            // if the current y is lower than the average by a head height, they are ducking
            animationController.gittinLow = ((position.columns.3.y + 0.15) < headYStanding)

        }
    
        // then we set the head node transform using the normal transform matrix
        headNode.transform = SCNMatrix4.init(position)
    }
    
    
    func ligntMeUp() {
        // lights
        spotLightNode.light = SCNLight()
        if let light = spotLightNode.light {
            light.type = .spot
            light.color = UIColor.white
            light.intensity = 1800
            light.castsShadow = true
            light.shadowColor = UIColor.black
//            light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            light.shadowRadius = 10
        }
        
        spotLightNode.position = SCNVector3(0,10,4)
        rootNode.addChildNode(spotLightNode)
        
        ambientLightNode.light = SCNLight()
        if let amLight = ambientLightNode.light {
            amLight.type = .ambient
            amLight.color = UIColor.white
            amLight.intensity = 200
        }
        rootNode.addChildNode(ambientLightNode)
        
        spotLightNode.constraints = [SCNLookAtConstraint(target: modelWrapper)]
        
    }
    
    func setUpRing() {
        let ringNode = SCNScene(named: "art.scnassets/ring.dae")
        let node = SCNNode()
        if let ringNodeUnwrapped = ringNode {
            // we need to do this as mixamo puts all on root level
            for child in ringNodeUnwrapped.rootNode.childNodes {
                node.addChildNode(child)
            }
        }
        
        ring.addChildNode(node)
        
    }
    
    
    // get the size of the model using the name chosen
    func getCharSize(using char: AnimationModelName) -> Float {
        switch char {
        case .maleFour:
            return 175.3
        case .maleOne:
            return 194.0
        case .maleThree:
            return 194.6
        case .maleTwo:
            return 193.6
        case .femaleFour:
            return 168.1
        case .femaleOne:
            return 179.0
        case .femaleThree:
            return 165.5
        case .femaleTwo:
            return 162.6
        }
    }
    
    func setUpDebugCam() -> SCNNode {
        let cam = SCNCamera()
        let camNode = SCNNode()
        camNode.camera = cam

        camNode.look(at: SCNVector3(0,0,0))
        camNode.position = SCNVector3(0,1.3,2)
        
        // need to rotate model for debug mode
        modelWrapper.rotation = SCNVector4(0, 1, 0, Float(180).degreesToRadians)
        
        rootNode.addChildNode(camNode)
        
        return camNode
    }
    
    func setUpChar() {
        // work out where to load the file from
        let file = "art.scnassets/boxers/\(modelName.rawValue)/\(modelName.rawValue).dae"
        
        // load the char dae
        let charModel = SCNScene(named: file)
        if let charUnwrapped = charModel {
            
            // we need to do this as mixamo puts all on root level
            for child in charUnwrapped.rootNode.childNodes {
                model.addChildNode(child)
            }
            
            // 'face' the correct direction, for the look at
            model.rotation = SCNVector4(0, 1, 0, Float(180).degreesToRadians)
            
            // work out the model size
            let modelSize = getCharSize(using: modelName)
            
            // calculate the scale using players size
            let factor: Float = 10000.0
            let diff: Float = (modelSize - usersHeight)

            if (diff > 0) {
                // if taller
                scaleOfModel = Float((modelSize - diff) / factor)
            } else {
                // if smaller
                scaleOfModel = Float((modelSize + diff) / factor)
            }
            
            // no idea why???
            scaleOfModel = scaleOfModel - 0.0063

            model.scale = SCNVector3(scaleOfModel, scaleOfModel, scaleOfModel)
            model.position = SCNVector3(0,0,0)
            
            // add collision detection to the hand nodes, these are ones we will add!
            
            let handBoxSize = CGFloat(0.1)
            let leftGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            let rightGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            
            let leftHandNode = SCNNode(geometry: leftGeo)
            let rightHandNode = SCNNode(geometry: rightGeo)
            
            // get the gloves model from file and put them on the hands
            
            if let leftForeArm = model.childNode(withName: BodyParts.leftForeArm.rawValue, recursively: true), let rightForeArm = model.childNode(withName: BodyParts.rightForeArm.rawValue, recursively: true) {
                // load the gloves dae
                if let gloves = SCNScene(named: "art.scnassets/gloves/gloves.dae") {
                    
                    
                    if let leftBoxingGlove = gloves.rootNode.childNode(withName: "left", recursively: true), let rightBoxingGlove = gloves.rootNode.childNode(withName: "right", recursively: true) {
                        
                        let scale = 0.87
                        leftBoxingGlove.scale = SCNVector3(scale, scale, scale)
                        rightBoxingGlove.scale = SCNVector3(scale, scale, scale)
                        
                        leftForeArm.addChildNode(leftBoxingGlove)
                        rightForeArm.addChildNode(rightBoxingGlove)
                    }
                }
            }
            
            
            if let lh = model.childNode(withName: BodyParts.leftPalm.rawValue, recursively: true), let rh = model.childNode(withName: BodyParts.rightPalm.rawValue, recursively: true) {
                
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
        }
    }
    
    // when we want to start the action
    func start() {
        // only show the health bar in survival mode
        healthManager?.addHealthBar(withScale: scaleOfModel, andModel: modelWrapper)
        // start callin them hits
        animationController?.didStart()
    }
    
    func setStartPosition(position: SCNVector3) {
        startPos = position
    }
    
    func showStartButton() {
        startButtonManager.placeStartButton(onScene: self)
    }
    
    func showChar() {
        modelWrapper.position = startPos
        // the floor os used to work out the y for the look at!
        theFloor = startPos.y
        rootNode.addChildNode(modelWrapper)
    }
    
    func showRing() {
        ring.position = startPos
        // move down a little for the floor
        ring.position.y = startPos.y - 1.5
        rootNode.addChildNode(ring)
    }
    
    func moveFloor() {
        // the 10 is half the size of the floor box :(
        floorNode.position = SCNVector3(0, (startPos.y - 0.01) + 10, 0)
        rootNode.addChildNode(floorNode)
    }
    
    func createFloor() {
        let box = SCNBox(width: 20, height: 20, length: 20, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 1, alpha: 0.05)
        mat.isDoubleSided = true
        box.firstMaterial = mat
        
        floorNode = SCNNode(geometry: box)
    }
    
    func createPlayerNode() {
        
        // add a box inside this piller, this is the one that represents the users head
        let headGeo = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        // do not want to see the head
        headGeo.firstMaterial?.diffuse.contents = UIColor.clear
        headNode = SCNNode(geometry: headGeo)
        
        headNode.physicsBody = SCNPhysicsBody.kinematic()
        if let physBod = headNode.physicsBody {
            physBod.categoryBitMask = CollisionCategory.player.rawValue
            physBod.contactTestBitMask = CollisionCategory.fighter.rawValue
        }
        
        rootNode.addChildNode(headNode)
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
}

