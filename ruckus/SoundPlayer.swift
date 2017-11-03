//
//  SoundPlayer.swift
//  ruckus
//
//  Created by Gareth on 03.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import AVFoundation

enum PlayerError: Error {
    case FileNotFound
    case CouldNotCreateAPlayer
    case CouldNotCreateAQueuePlayer
    case CouldNotSetBgMode
}

protocol PlaysSounds {
    func setNewVolume(_ newVolume: Float)
    func setToBgSoundMode() throws
    func play(_ sound: String, withExtension ext: String, loop: Bool) throws
    func playList(_ sounds: [String], withExtensions ext: String, atDirectory directory: String) throws
}

protocol ListensToPlayEndEvents: class {
    func didFinishPlaying()
}

class SoundPlayer: NSObject, PlaysSounds {
    
    var player: AVAudioPlayer!
    // to keep a ref to anything looping (can only loop one thing at a time)
    var loopingPlayer: AVAudioPlayer!
    var queuePlayer: AVQueuePlayer!
    weak var delegate: ListensToPlayEndEvents?
    var setBgMode = false
    var looping = false
    var volume: Float = 1.0
    
    static let sharedInstance = SoundPlayer()
    
    @objc func setNewVolume(_ newVolume: Float) {
        volume = newVolume
    }
    
    func setToBgSoundMode() throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            setBgMode = true
        } catch {
            throw PlayerError.CouldNotSetBgMode
        }
    }
    
    // public function to play sound
    public func play(_ sound: String, withExtension ext: String, loop: Bool = false) throws {
        guard let url = Bundle.main.url(forResource: sound, withExtension: ext) else {
            throw PlayerError.FileNotFound
        }
        
        do {
            if (!setBgMode) {
                try setToBgSoundMode()
            }
            
            // create a ref to the looping player
            if (loop) {
                loopingPlayer = try AVAudioPlayer(contentsOf: url)
                guard let loopingPlayer = loopingPlayer else {
                    throw PlayerError.CouldNotCreateAPlayer
                }
                loopingPlayer.numberOfLoops = -1
                loopingPlayer.play()
                looping = true
            } else {
                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else {
                    throw PlayerError.CouldNotCreateAPlayer
                }
                
                player.volume = volume
                player.play()
            }
            
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func playList(_ sounds: [String], withExtensions ext: String, atDirectory directory: String = "") throws {
        
        var audioItems: [AVPlayerItem] = []
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        for index in 0..<sounds.count {
            let sound = sounds[index]
            guard let url = Bundle.main.url(forResource: (directory + sound), withExtension: ext) else {
                throw PlayerError.FileNotFound
            }
            
            let item = AVPlayerItem(url: url)
            
            // if we are on the last item add an event listener to the finnished playing event
            // for that item
            if ((index + 1) == sounds.count) {
                // add the notification
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(didFinishPlayingAudio),
                    name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                    object: item
                )
            }
            
            audioItems.append(item)
        }
        
        do {
            if (!setBgMode) {
                try setToBgSoundMode()
            }
            
            queuePlayer = AVQueuePlayer(items: audioItems)
            
            queuePlayer.volume = volume
            
            guard let queuePlayer = queuePlayer else {
                throw PlayerError.CouldNotCreateAQueuePlayer
            }
            queuePlayer.play()
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
    }
    
    // cb for when the audio has finished playing
    @objc func didFinishPlayingAudio(item: AVPlayerItem) {
        // remove the last notification first
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item
        )
        self.delegate?.didFinishPlaying()
    }
}
