//
//  MainCamEntity.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import SceneKit
import GameKit

class PlayerEntity: GKEntity {
    let agent:GKAgent3D = GKAgent3D()
    
    init(usingNode node: SCNNode) {
        super.init()
        
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
