//
//  HitCaller.swift
//  ruckus
//
//  Created by Gareth on 13.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

protocol CallsHits {
    func runCombo() -> Void
    func updateVoiceStyle() -> Void
}


class HitCaller: CallsHits {
    let combosModel: Combos
    let combos: [[Move]]
    // need to use shared instance as others are waiting for callback event
    let player: SoundPlayer = SoundPlayer.sharedInstance
    var voiceStyle: String
    var hitsCalled: Int = 0
    
    static let sharedInstance = HitCaller()
    
    
    init() {
        combosModel = Combos()
        combos = combosModel.getPossibleCombos()
        voiceStyle = combosModel.getVoiceStyle()
    }
    
    func updateVoiceStyle() -> Void {
        voiceStyle = combosModel.getVoiceStyle()
    }
    
    
    func runCombo() -> Void {
        
        // get a random combo
        let randomIndex = Int(arc4random_uniform(UInt32(combos.count)))
        let combo = combos[randomIndex]
        var stringOfCombos: [String] = []
        
        for hit in combo {
            // keep track of the hits called
            hitsCalled = hitsCalled + 1
            // add the string name of the sound to the flie
            stringOfCombos.append(hit.rawValue)
        }

        
        let directory = "Sounds/\(voiceStyle)/"
        
        do {
            try player.playList(stringOfCombos, withExtensions: "wav", atDirectory: directory)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}
