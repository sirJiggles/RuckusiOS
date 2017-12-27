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
    var players: [SCNAnimationPlayer] = []
    let animations: [Move] = [.jab, .rightHook, .cross, .stance]
    var runningPlayer: SCNAnimationPlayer?
    
    static let sharedInstance = ARAnimationController()
    
    init() {
        
    }
    
    convenience init(withModel model: SCNNode) {
        self.init()
        self.model = model
        setUpMoves()
        
        // just to test
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(runCombo), userInfo: nil, repeats: true)
    }
    
    @objc func runCombo() {
        
        let combo = HitGiver.sharedInstance.getCombo()
        var i: Double = 0.0
        for move in combo {
            playMove(named: move, after: i)
            i = i + 1.6
        }
    }
    
    func playMove(named move: Move, after: Double) {
        if let player = model.animationPlayer(forKey: move.rawValue) {
            print("got the move named \(move.rawValue)!")
            
            Timer.scheduledTimer(timeInterval: after, target: self, selector: #selector(whosGotta(_:)), userInfo: player, repeats: false)
            
            runningPlayer = player
        }
    }
    
    @objc func whosGotta(_ timer: Timer) {
        if let player = timer.userInfo as? SCNAnimationPlayer {
            // stop other animations
            for pl in players {
                pl.stop(withBlendOutDuration: 0.2)
            }
            player.play()
        }
       
    }
    
    func setUpMoves() {
        for animation in animations {
            let player = AnimationLoader.loadAnimation(fromSceneNamed: "art.scnassets/\(animation.rawValue).dae")

            switch (animation) {
            case .cross, .leftHook:
                player.speed = 0.7
            case .jab:
                player.speed = 0.5
            default:
                player.speed = 0.7
            }
            player.blendFactor = 0.75
            players.append(player)

            model.addAnimationPlayer(player, forKey: animation.rawValue)
        }
    }
}
