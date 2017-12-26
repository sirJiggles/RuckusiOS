//
//  ARAnimationController.swift
//  ruckus
//
//  Created by Gareth on 26.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import SceneKit

class ARAnimationController {
    var model = SCNNode()
    var moves: [AnimatedMove]  = []
    let animations = ["jab", "stance"]
    var runningPlayer: SCNAnimationPlayer?
    
    static let sharedInstance = ARAnimationController()
    
    init() {
        
    }
    
    convenience init(withModel model: SCNNode) {
        self.init()
        self.model = model
        setUpMoves()
        
        // just to test
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(runCombo), userInfo: nil, repeats: true)
    }
    
    @objc func runCombo() {
        
        let combo = HitGiver.sharedInstance.getCombo()
        for move in combo {
            playMove(named: move)
        }
    }
    
    func playMove(named animationName: String) {
        
        
        for move in moves {
            if let player = move[animationName] {
                if let running = runningPlayer {
                    running.stop()
                }
                print("got the move named \(animationName)!")
                player.play()
                
                runningPlayer = player
            }
        }
    }
    
    func setUpMoves() {
        for animation in animations {
            let player = AnimationLoader.loadAnimation(fromSceneNamed: "art.scnassets/\(animation).dae")
            let move: AnimatedMove = [
                "\(animation)": player
            ]
            player.speed = 0.5
            moves.append(move)
            model.addAnimationPlayer(player, forKey: animation)
        }
    }
}
