//
//  FighterEntity.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import SceneKit
import GameKit

class FighterEntity: GKEntity {
    
    let agent: GKAgent3D
    
    init(withTargetAgent targetAgent :GKAgent3D, andNode node :SCNNode) {
        agent = TargetingAgent(withTargetAgent: targetAgent)
        
        super.init()
        
        // The agent update delegates get called in move component
//        agent.delegate = self
        
        let nodeComponent = NodeComponent(withNode: node)
        addComponent(nodeComponent)
        
        let moveComponent = MoveComponent()
        addComponent(moveComponent)
        
        agent.delegate = moveComponent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
