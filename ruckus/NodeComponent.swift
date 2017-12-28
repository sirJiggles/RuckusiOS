//
//  NodeComponent.swift
//  ruckus
//
//  Created by Gareth on 27.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import SceneKit
import GameplayKit

class NodeComponent: GKComponent {
    
    let node: SCNNode
    
    init(withNode node :SCNNode) {
        self.node = node
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
