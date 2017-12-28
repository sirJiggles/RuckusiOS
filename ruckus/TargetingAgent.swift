//
//  TargetingAgent.swift
//  ruckus
//
//  Created by Gareth on 28.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import GameKit

class TargetingAgent: GKAgent3D {
    
    let target:GKAgent3D
    
    required init(withTargetAgent targetAgent:GKAgent3D) {
        
        target = targetAgent
        
        super.init()
        
        let seek = GKGoal(toSeekAgent: targetAgent)
        
        self.behavior = GKBehavior(goals: [seek], andWeights: [1])
        
        self.maxSpeed = 4000
        self.maxAcceleration = 4000
        self.mass = 0.4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
