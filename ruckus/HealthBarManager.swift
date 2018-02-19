//
//  HealthBarController.swift
//  ruckus
//
//  Created by Gareth on 13.02.18.
//  Copyright © 2018 Gareth. All rights reserved.
//
import SceneKit

protocol ControlsHeath {
    func stopHealthTicking() -> Void
    func addHealthBar(withScale scale: Float, andModel model: SCNNode) -> Void
    
}

class HealthBarManager: ControlsHeath {
    var survivalTime: Double = 0
    var healthTicker = Timer()
    var settingsAccessor: SettingsAccessor?
    var scene: ARScene?
    
    convenience init(withScene scene: ARScene) {
        self.init()
        self.scene = scene
        settingsAccessor = SettingsAccessor()
    }
    
    func fetchSettings() {
        if let _ = settingsAccessor?.getSurvivalEnabled() {
            if let survivalTime = settingsAccessor?.getSurvivalTime() {
                self.survivalTime = survivalTime
            }
        }
    }
    
    func addHealthBar(withScale scale: Float, andModel model: SCNNode) {
        
        if survivalTime <= 0 {
            return
        }
        // add the node for the health of the char
        let healthsize: (CGFloat, CGFloat) = (1, 0.1)
        let width: CGFloat = 0.02
        
        let healthGeo = SCNBox(width: width, height: healthsize.1, length: healthsize.0, chamferRadius: 0.005)
        
        healthGeo.firstMaterial?.diffuse.contents = UIColor.green
        let healthNode = SCNNode(geometry: healthGeo)
        
        healthNode.castsShadow = false
        
        model.addChildNode(healthNode)
        
        healthNode.rotation = SCNVector4(0, 1, 0, Float(90).degreesToRadians)
        
        // put it above the model nodes head
        healthNode.position = SCNVector3(0, (scale * 185), 0)
        
        let oneHealthUnit = healthsize.0 / CGFloat(survivalTime)
        
        healthTicker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            healthGeo.length = healthGeo.length - oneHealthUnit
            
            // work out what sort of colour the health bar should be depending on
            // how much is left
            let left = (healthGeo.length / healthsize.0) * 100
            
            var colour: UIColor
            switch left {
            case _ where left <= 80 && left > 60:
                colour = UIColor(netHex: 0x4d9900)
            case _ where left <= 60 && left > 40:
                colour = UIColor(netHex: 0x739900)
            case _ where left <= 40 && left > 20:
                colour = UIColor(netHex: 0x999900)
            case _ where left <= 20 && left > 10:
                colour = UIColor(netHex: 0x997300)
            case _ where left <= 10:
                colour = UIColor(netHex: 0x994d00)
            default:
                colour = UIColor(netHex: 0x269900)
                break
            }
            healthGeo.firstMaterial?.diffuse.contents = colour
            
            if left <= 0 {
                // stop the ticker and send out the event, I am done sir!
                self.healthTicker.invalidate()
                if let scene = self.scene {
                    scene.gameDelegate?.endGame()
                    scene.empty()
                }
            }
        })
    }
    
    func stopHealthTicking() {
        healthTicker.invalidate()
    }
}
