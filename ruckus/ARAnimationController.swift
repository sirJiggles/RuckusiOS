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
    let animations: [Move] = [.jab, .cross, .idle, .leftHook, .rightHook, .bigCross]

    
    var runningPlayer: SCNAnimationPlayer?
    var speed: Double = 1.0
    
    var settingsAccessor: SettingsAccessor?
    
    static let sharedInstance = ARAnimationController()
    
    init() {
        settingsAccessor = SettingsAccessor()
        
        if let difficulty = settingsAccessor?.getARDifficulty() {
            speed = Double(difficulty + 1.0)
        }
    }
    
    convenience init(withModel model: SCNNode) {
        self.init()
        self.model = model
        setUpMoves()
        
        // start with the idle stance on init
        playMove(named: .idle, after: 0)
        
        // just to test
        Timer.scheduledTimer(timeInterval: 6.0 / speed, target: self, selector: #selector(runCombo), userInfo: nil, repeats: true)
    }
    
    @objc func runCombo() {
        
        let combo = HitGiver.sharedInstance.getCombo()
        var i: Double = 0.0
        for move in combo {
            playMove(named: move, after: i)
            i = i + (1 / speed) - 0.2
        }
    }
    
    func playMove(named move: Move, after: Double) {
        if let player = model.animationPlayer(forKey: move.rawValue) {
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
            print("we are trying to find \(animation.rawValue).dae")
            let player = AnimationLoader.loadAnimation(fromSceneNamed: "art.scnassets/\(animation.rawValue).dae")
            
            switch (animation) {
            case .idle:
                player.speed = 1.2
            default:
                player.speed = CGFloat(speed + 0.2)
            }

            players.append(player)

            model.addAnimationPlayer(player, forKey: animation.rawValue)
        }
    }
}
