//
//  SettingsAccessor.swift
//  ruckus
//
//  Created by Gareth on 13.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

protocol GetsSettings {
    func getVolume() -> Float
    func getDifficulty() -> Float
    func getCallOuts() -> Bool
    func getCrowdEnabled() -> Bool
}


struct SettingsAccessor: GetsSettings {
    let settings: Settings
    
    init() {
        settings = Settings(usingPlist: "Settings")
        
        do {
            try settings.initPlist()
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getCallOuts() -> Bool {
        do {
            if let enabled = try settings.getValue(forKey: PossibleSetting.callOutHits.rawValue) as? String {
                return (enabled == "1")
            }
            return false
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getCrowdEnabled() -> Bool {
        do {
            if let enabled = try settings.getValue(forKey: PossibleSetting.backgroundCrowd.rawValue) as? String {
                return (enabled == "1")
            }
            return false
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getVolume() -> Float {
        do {
            if let volume = try settings.getValue(forKey: PossibleSetting.volume.rawValue) as? Float {
                return volume
            }
            return 0.75
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    func getDifficulty() -> Float {
        do {
            if let difficulty = try settings.getValue(forKey: PossibleSetting.difficulty.rawValue) as? Float {
                return difficulty
            }
            return 0.75
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getModelName() -> String {
        do {
            if let model = try settings.getValue(forKey: PossibleSetting.model.rawValue) as? String {
                return model
            }
            return "robot"
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getUsersHeight() -> Float {
        do {
            if let height = try settings.getValue(forKey: PossibleSetting.userHeight.rawValue) as? Float {
                return height
            }
            return 170.0
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}
