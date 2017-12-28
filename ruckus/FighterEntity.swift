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
    
    init(withTargetAgent targetAgent :GKAgent3D, andNode node :SCNNode) {
        super.init()
        
        let nodeComponent = NodeComponent(withNode: node)
        addComponent(nodeComponent)
        
        let moveComponent = MoveComponent()
        addComponent(moveComponent)
        
        let targetingAgent = TargetingAgent(withTargetAgent: targetAgent)
        // The agent update delegates get called in move component
        targetingAgent.delegate = moveComponent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
