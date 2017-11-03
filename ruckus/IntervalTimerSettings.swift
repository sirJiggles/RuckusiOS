//
//  IntervalTimerSettings.swift
//  ruckus
//
//  Created by Gareth on 01/04/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

class IntervalTimerSettings {
    var settings: Settings
    
    init() {
        settings = Settings(usingPlist: "Settings")
        
        do {
            try settings.initPlist()
        } catch let error {
            fatalError("\(error)")
        }
        
    }
    
    
    func getSettings() -> [String] {
        let settingsFromStore: [String]
        
        do {
            settingsFromStore = [
                try settings.getValue(forKey: "roundTime") as! String,
                try settings.getValue(forKey: "pauseTime") as! String,
                try settings.getValue(forKey: "preperationTime") as! String,
                try settings.getValue(forKey: "warmUpTime") as! String,
                try settings.getValue(forKey: "stretchTime") as! String,
                try settings.getValue(forKey: "rounds") as! String,
            ]
        } catch let error {
            fatalError("\(error)")
        }
        
        return settingsFromStore

    }
    
}
