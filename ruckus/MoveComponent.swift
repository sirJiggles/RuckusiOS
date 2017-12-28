//
//  MoveComponent.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import GameKit
import SceneKit

class MoveComponent : GKAgent3D, GKAgentDelegate {
    
    // MARK: - Agent delegate
    func agentWillUpdate(_ agent: GKAgent) {
        print("agent will update")
        guard let component = entity?.component(ofType: NodeComponent.self) else {
            return
        }
        
        position = float3(component.node.position)
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        print("agent did update")
        guard let component = entity?.component(ofType: NodeComponent.self) else {
            return
        }
        
        component.node.position = SCNVector3(position)
    }
}
