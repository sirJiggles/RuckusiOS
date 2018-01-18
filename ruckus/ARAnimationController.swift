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
    let animations: [Move] = [
        .idle,
        .jab,
        .cross,
        .rightHook,
        .bigCross,
        .jabLow,
        .crossLow,
        .rightHookLow,
        .bigCrossLow
    ]
    
    var speed: Double = 0.7
    var callOutsEnabled: Bool = true
    
    var settingsAccessor: SettingsAccessor?
    
    var aniamtionSequences: [Timer] = []
    var attackTimer: Timer?
    var afterPunchTimer: Timer?
    var currentPlayer: SCNAnimationPlayer?
    
    static let sharedInstance = ARAnimationController()
    
    let soundManager = ARSoundManager()
    
    var hitting = false
    // this gets set externally, when the head moves bellow a threshold
    var gittinLow = false
    
    init() {
        settingsAccessor = SettingsAccessor()
        
        if let difficulty = settingsAccessor?.getDifficulty() {
            speed = Double(difficulty) + 0.7
        }
        
        if let enabled = settingsAccessor?.getCallOuts() {
            callOutsEnabled = enabled
        }
    }
    
    convenience init(withModel model: SCNNode) {
        self.init()
        self.model = model
        setUpMoves()
        
        // start with the idle stance on init
        playMove(named: .idle, after: 0)
    }
    
    @objc func runCombo() {
        // clear all the animation timers from the last combo
        aniamtionSequences = []
        let combo = HitGiver.sharedInstance.getCombo()
        var i: Double = 0.0
        var index = 1
        for move in combo {
            playMove(named: move, after: i)
            i = i + getHitSpeedFor(move: move)
            index += 1
        }
    }
    
    // this gets called when we switch to a form of working mode
    func didStart() {
        runCombo()
        // just go into full attack mode
        attackTimer = Timer.scheduledTimer(timeInterval: 5.0 / speed, target: self, selector: #selector(runCombo), userInfo: nil, repeats: true)
    }
    
    // this gets called when we go into a paused / rest / ended mode
    func didStop() {
        // stop all that are qeued
        for timer in aniamtionSequences {
            timer.invalidate()
        }
        
        attackTimer?.invalidate()
        
        // stop the animations running
        for pl in players {
            pl.stop(withBlendOutDuration: 0.1)
        }
        // play the idle
        playMove(named: .idle, after: 0)
    }
    
    func playMove(named move: Move, after: Double) {
        let moveTimer = Timer.scheduledTimer(timeInterval: after, target: self, selector: #selector(whosGotta(_:)), userInfo: [move], repeats: false)
        aniamtionSequences.append(moveTimer)
    }
    
    // adjust this for how fast the model hits
    func getHitSpeedFor(move: Move) -> Double {
        var factor = 0.6
        switch move {
        case .bigCross, .bigCrossLow:
            factor = 1.1
        case .cross, .crossLow:
            factor = 0.5
        default:
            factor = 0.6
        }
        return factor / speed
    }
    
    @objc func whosGotta(_ timer: Timer) {
        if let info = timer.userInfo as? [AnyObject] {
            if let move = info[0] as? Move {
                // we can also load the low version of each move, if
                // at the time of playing it the user is low ;)
                let moveName = (self.gittinLow && move != .idle) ? "\(move.rawValue)Low" : move.rawValue
                
                if let player = model.animationPlayer(forKey: moveName) {
                    // stop running aniamtion
                    if let runningPlayer = currentPlayer{
                        runningPlayer.stop(withBlendOutDuration: 0.1)
                    }
                    
                    player.play()
                    currentPlayer = player
                    
                    // play the swoosh sound for each punch
                    if move != .idle {
                        // we know the model is hitting
                        hitting = true
                        // should be not hitting and swooshing just before end of hit
                        let timeInBetweenPunches: Double = 0.2 / speed
                        let delay = getHitSpeedFor(move: move) - timeInBetweenPunches
                        // run timer after time for move - time in between
                        Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
                            self.soundManager.swoosh()
                            self.hitting = false
                        })
                    }
                }
            }
        }
    }
    
    func setUpMoves() {
        for animation in animations {
            let player = AnimationLoader.loadAnimation(fromSceneNamed: "art.scnassets/animations/\(animation.rawValue).dae")
            
            switch (animation) {
            case .idle:
                player.speed = 1.2
            // lets speed up the big cross a little
            case .bigCross, .bigCrossLow:
                player.speed = CGFloat(speed + 0.2)
            default:
                player.speed = CGFloat(speed)
            }

            players.append(player)

            model.addAnimationPlayer(player, forKey: animation.rawValue)
            
            // for some reason they all start!
            player.stop()
        }
    }
}
