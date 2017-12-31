//
//  TargetingAgent.swift
//  ruckus
//
//  Created by Gareth on 28.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import GameKit

class TargetingAgent: GKAgent3D {
    
    required init(withTargetAgent targetAgent:GKAgent3D) {
        
        super.init()
        
        let seek = GKGoal(toSeekAgent: targetAgent)
        
        let dontGetToClose = GKGoal(toSeparateFrom: [targetAgent], maxDistance: 0.1, maxAngle: 0.1)

        self.behavior = GKBehavior(goals: [seek, dontGetToClose], andWeights: [0.9, 0.8])
        
        self.mass = 0.1
//        self.maxSpeed = 1
//        self.maxAcceleration = 0.4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
