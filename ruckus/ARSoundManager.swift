//
//  ARSoundManager.swift
//  ruckus
//
//  Created by Gareth on 14.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import Foundation

protocol PlaysPunchSounds {
    func playPunchSound() -> Void
}

protocol ControllsTheCrowd {
    func startCrowd() -> Void
    func stopTheCrowd() -> Void
}

protocol PlayesSwooshingNoises {
    func swoosh() -> Void
}


class ARSoundManager: PlaysPunchSounds, ControllsTheCrowd, PlayesSwooshingNoises {
    let player = SoundPlayer()
    let playerQue = DispatchQueue(label: "ruckus.ar_sound_que", qos: DispatchQoS.background)
    let swooshQue = DispatchQueue(label: "ruckus.ar_sound_que_swoosh", qos: DispatchQoS.background)
    var crowdSoundsEnabled:Bool = false
    let settingsAccessor = SettingsAccessor()
    
    func sync() {
        crowdSoundsEnabled = settingsAccessor.getCrowdEnabled()
    }
    
    func playPunchSound() {
        playerQue.async {
            let randomIndex = Int(arc4random_uniform(UInt32(4))) + 1
            do {
                try self.player.play("punch_\(randomIndex)", withExtension: "wav", loop: false)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func startCrowd() {
        if !crowdSoundsEnabled {
            return
        }
        if player.looping {
            return
        }
        // start the sound for the crowd if the setting is turned on
        do {
            try player.play("crowd", withExtension: "wav", loop: true)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func stopTheCrowd() {
        if !crowdSoundsEnabled {
            return
        }
        if (player.looping) {
            player.loopingPlayer.stop()
            player.looping = false
        }
    }
    
    
    
    func swoosh() {
        // new que so does not mess with punch sound
        swooshQue.async {
            do {
                try self.player.play("swoosh", withExtension: "wav", loop: false)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
    }
    
}
