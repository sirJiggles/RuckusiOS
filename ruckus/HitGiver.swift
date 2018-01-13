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
        [.jab, .jab, .cross, .idle],
        [.jab, .cross, .leftHook, .idle],
        [.leftHook, .rightHook, .idle],
        [.jab, .jab, .leftHook],
        [.leftHook, .bigCross, .leftHook, .idle],
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

    var hitsthGiveth: Int = 0
    
    static let sharedInstance = HitGiver()
    
    init(){
        
    }
    
    func getCombo() -> [Move] {
        
        // get a random combo
        let randomIndex = Int(arc4random_uniform(UInt32(combos.count)))
        let combo = combos[randomIndex]
        var stringOfCombos: [Move] = []
        
        for hit in combo {
            // keep track of the hits called
            hitsthGiveth = hitsthGiveth + 1
            // add the string name of the sound to the flie
            stringOfCombos.append(hit)
        }
        
        return stringOfCombos
    }
}
