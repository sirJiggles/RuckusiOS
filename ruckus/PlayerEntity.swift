//
//  MainCamEntity.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import SceneKit
import GameKit

class PlayerEntity: GKEntity, GKAgentDelegate {
    let agent:GKAgent3D = GKAgent3D()
    
    init(usingNode node: SCNNode) {
        super.init()
        
        let nodeComponent = NodeComponent(withNode: node)
        addComponent(nodeComponent)
        
//        let moveComponent = MoveComponent()
//        addComponent(moveComponent)
        agent.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        print("agent will update player")
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = self.component(ofType: NodeComponent.self) else {
            return
        }
        
        agent3d.position = float3(component.node.position)
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        print("agent did update player")
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = self.component(ofType: NodeComponent.self) else {
            return
        }
        
        component.node.position = SCNVector3(agent3d.position)
    }
}
