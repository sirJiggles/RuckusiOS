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
        
        self.behavior = GKBehavior(goal: seek, weight: 1)
        
//        self.maxSpeed = 4000
//        self.maxAcceleration = 4000
        self.mass = 0.4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
