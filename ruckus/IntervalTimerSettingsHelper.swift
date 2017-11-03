//
//  IntervalTimerSettingsService.swift
//  ruckus
//
//  Created by Gareth on 02/04/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

// the job of this struct is to fetch the settings for initilizing
// the interval timer class as this class can be used in a place with no plist and so on
struct IntervalTimerSettingsHelper {
    let settings: Settings
    
    init() {
        settings = Settings(usingPlist: "Settings")
        
        do {
            try settings.initPlist()
        } catch {
            // TODO handle this
            fatalError()
        }
    }
    
    func getSettings() -> [String:String] {
        
        var settingsForTimer: [String:String] = [:]
        
        do {
            if let intervalTime = try settings.getValue(forKey: PossibleSetting.roundTime.rawValue) as? String {
                settingsForTimer[PossibleSetting.roundTime.rawValue] = intervalTime
            }
            if let restTime = try settings.getValue(forKey: PossibleSetting.pauseTime.rawValue) as? String {
                settingsForTimer[PossibleSetting.pauseTime.rawValue] = restTime
            }
            if let prepTime = try settings.getValue(forKey: PossibleSetting.preperationTime.rawValue) as? String {
                settingsForTimer[PossibleSetting.preperationTime.rawValue] = prepTime
            }
            if let warmupTime = try settings.getValue(forKey: PossibleSetting.warmUpTime.rawValue) as? String {
                settingsForTimer[PossibleSetting.warmUpTime.rawValue] = warmupTime
            }
            if let stretchTime = try settings.getValue(forKey: PossibleSetting.stretchTime.rawValue) as? String {
                settingsForTimer[PossibleSetting.stretchTime.rawValue] = stretchTime
            }
            if let intervals = try settings.getValue(forKey: PossibleSetting.rounds.rawValue) as? String {
                settingsForTimer[PossibleSetting.rounds.rawValue] = intervals
            }
        } catch {
            // TODO handle this
            fatalError()
        }
        
        return settingsForTimer
        
    }
}
