//
//  MoveComponent.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import GameKit
import SceneKit

class MoveComponent: GKComponent, GKAgentDelegate {
    
    // MARK: - Agent delegate
    func agentWillUpdate(_ agent: GKAgent) {
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = entity?.component(ofType: NodeComponent.self) else {
            return
        }

        agent3d.position = float3(component.node.position)
    }

    func agentDidUpdate(_ agent: GKAgent) {
        guard let agent3d = agent as? GKAgent3D else {
            return
        }
        guard let component = entity?.component(ofType: NodeComponent.self) else {
            return
        }

        component.node.position = SCNVector3(agent3d.position)
    }
}
