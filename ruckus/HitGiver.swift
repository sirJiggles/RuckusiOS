//
//  HitGiver.swift
//  ruckus
//
//  Created by Gareth on 26.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

protocol GivesHites {
    func getCombo() -> [Move]
}


class HitGiver: GivesHites {
    let combos: [[Move]] = [
//        [.jab, .cross, .leftHook, .idle],
//        [.quadPunch, .idle],
//        [.jab, .cross, .hook, .uppercut, .idle],
//        [.uppercut, .idle],
//        [.jab, .cross, .uppercut],
//        [.bigCross, .uppercut],
//        [.leftHook, .rightHook, .idle],
//        [.jab, .jab, .leftHook],
//        [.leftHook, .bigCross, .leftHook, .idle],
        [.jab, .jab, .cross, .idle],
        [.jab, .bigCross, .idle],
        [.bigCross, .idle],
        [.jab, .cross, .idle],
        [.rightHook, .jab, .idle],
        [.jab, .cross, .rightHook, .idle],
        [.rightHook, .jab, .cross, .idle],
        [.rightHook, .jab, .bigCross, .idle],
        [.jab, .rightHook, .idle],
        [.jab, .jab, .idle]
    ]
    
    static let sharedInstance = HitGiver()
    
    func getCombo() -> [Move] {
        
        // get a random combo
        let randomIndex = Int(arc4random_uniform(UInt32(combos.count)))
        let combo = combos[randomIndex]
        var stringOfCombos: [Move] = []
        
        for hit in combo {
            if hit != .idle {
                ARGameManager.sharedInstance.increaseHitAmount()
            }
            // add the string name of the sound to the flie
            stringOfCombos.append(hit)
        }
        
        return stringOfCombos
    }
}
