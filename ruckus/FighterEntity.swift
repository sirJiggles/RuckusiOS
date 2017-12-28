//
//  FighterEntity.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import SceneKit
import GameKit

class FighterEntity: GKEntity, GKAgentDelegate {
    
    let agent: GKAgent3D
    
    init(withTargetAgent targetAgent :GKAgent3D, andNode node :SCNNode) {
        agent = TargetingAgent(withTargetAgent: targetAgent)
        
        super.init()
        
        // The agent update delegates get called in move component
        agent.delegate = self
        
        let nodeComponent = NodeComponent(withNode: node)
        addComponent(nodeComponent)
        
//        let moveComponent = MoveComponent()
        
//        addComponent(moveComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        print("agent will update fighter")
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = self.component(ofType: NodeComponent.self) else {
            return
        }
        
        agent3d.position = float3(component.node.position)
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        print("agent did update fighter")
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = self.component(ofType: NodeComponent.self) else {
            return
        }
        
        component.node.position = SCNVector3(agent3d.position)
    }
}
