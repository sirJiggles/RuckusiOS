//
//  HitGiver.swift
//  ruckus
//
//  Created by Gareth on 26.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

protocol GivesHites {
    func getCombo() -> [String]
}


class HitGiver: GivesHites {
    let combos: [[Move]] = [
        [.jab, .stance],
        [.jab, .stance, .stance],
        [.jab, .stance, .jab]
    ]

    var hitsthGiveth: Int = 0
    
    static let sharedInstance = HitGiver()
    
    init(){
        
    }
    
    func getCombo() -> [String] {
        
        // get a random combo
        let randomIndex = Int(arc4random_uniform(UInt32(combos.count)))
        let combo = combos[randomIndex]
        var stringOfCombos: [String] = []
        
        for hit in combo {
            // keep track of the hits called
            hitsthGiveth = hitsthGiveth + 1
            // add the string name of the sound to the flie
            stringOfCombos.append(hit.rawValue)
        }
        
        return stringOfCombos
    }
}
