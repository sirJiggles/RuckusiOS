//
//  Combos.swift
//  ruckus
//
//  Created by Gareth on 13.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

protocol ReturnsCombos {
    func getPossibleCombos() -> [[Move]]
    func getVoiceStyle() -> String
}

// all of the possible moves
enum Move: String {
    case jab
    case cross
    case hook
    case sideKick
    case roundKick
    case pushKick
    case elbow
    case shinKick
    case spinningBackFist
    case jumpingRoundKick
    case jumpingFrontKick
    case jumpingSideKick
    case spinningSideKick
    case spinningHookKick
    case duck
    case slip
    case cover
    case uppercut
    case knee
    case idle
    case leftHook
    case rightHook
    case bigCross
}

struct Combos: ReturnsCombos {
    let settings: Settings
    
    // define all of the combos, these then get combined based on the settings
    // in the protocal later
    
    let punches: [[Move]] = [
        [.jab, .cross, .hook],
        [.jab, .jab, .hook],
        [.jab],
        [.jab, .cross],
        [.jab, .hook, .jab],
        [.cross, .hook],
        [.jab, .hook, .hook],
        [.cross, .jab, .hook],
        [.cross, .hook, .hook],
        [.cross, .hook, .hook, .jab],
        [.jab, .cross, .hook, .hook],
        [.jab, .jab, .hook],
        [.hook, .hook, .jab, .cross],
        [.jab, .hook, .jab, .cross],
        [.jab, .cross, .hook],
        [.jab, .jab, .jab],
        [.hook, .cross, .jab, .cross],
        [.cross, .jab, .cross],
        [.jab, .jab, .cross, .jab]
    ]
    
    let uppercuts: [[Move]] = [
        [.jab, .uppercut],
        [.uppercut, .uppercut],
        [.jab, .jab, .uppercut],
        [.jab, .cross, .uppercut]
    ]
    
    let kicks: [[Move]] = [
        [.pushKick, .jab, .cross],
        [.pushKick, .roundKick],
        [.roundKick, .sideKick],
        [.sideKick],
        [.roundKick, .hook],
        [.roundKick, .jab],
        [.jab, .jab, .roundKick],
        [.roundKick, .roundKick],
        [.sideKick, .jab, .cross],
        [.jab, .cross, .hook, .roundKick],
        [.jab, .cross, .hook, .sideKick]
    ]
    
    let dirty: [[Move]] = [
        [.jab, .elbow],
        [.elbow, .elbow],
        [.jab, .jab, .elbow],
        [.shinKick, .hook],
        [.jab, .shinKick, .hook],
        [.jab, .shinKick],
        [.jab, .cross, .shinKick],
        [.hook, .spinningBackFist],
        [.jab, .cross, .hook, .spinningBackFist],
        [.jab, .hook, .spinningBackFist],
        [.cross, .hook, .spinningBackFist],
        [.knee, .knee],
        [.jab, .cross, .hook, .knee],
        [.jab, .jab, .knee],
        [.jab, .cross, .knee]
    ]
    
    let jumpingKicks: [[Move]] = [
        [.jumpingRoundKick],
        [.jumpingSideKick],
        [.jumpingFrontKick]
    ]
    
    let spinningKicks : [[Move]] = [
        [.hook, .spinningSideKick],
        [.spinningSideKick],
        [.spinningHookKick],
        [.jab, .cross, .hook, .spinningHookKick],
        [.jab, .cross, .hook, .spinningSideKick],
        [.spinningSideKick, .jab, .cross],
        [.sideKick, .spinningSideKick],
        [.pushKick, .spinningSideKick],
        [.roundKick, .roundKick, .spinningSideKick],
        [.pushKick, .spinningHookKick]
    ]
    
    let spinningKicksAndDodges: [[Move]] = [
        [.slip, .hook, .spinningSideKick],
        [.cover, .jab, .spinningSideKick]
    ]
    
    let dodges: [[Move]] = [
        [.jab, .cross, .duck],
        [.duck],
        [.jab, .slip, .hook],
        [.cover, .cover],
        [.jab, .cross, .cover],
        [.cover, .cross, .hook],
        [.hook, .duck, .hook],
        [.jab, .duck, .hook],
        [.slip, .hook],
        [.slip, .slip],
        [.jab, .cross, .slip],
        [.cover, .duck, .hook]
    ]
    
    let kicksAndDrity: [[Move]] = [
        [.pushKick, .elbow, .hook],
        [.elbow, .hook, .roundKick],
        [.pushKick, .shinKick],
        [.roundKick, .hook, .elbow],
        [.pushKick, .elbow]
    ]
    
    init() {
        settings = Settings(usingPlist: "Settings")
        
        do {
            try settings.initPlist()
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getVoiceStyle() -> String {
        do {
            if let voiceStyle = try settings.getValue(forKey: PossibleSetting.voiceStyle.rawValue) as? String {
                return voiceStyle
            }
            return "Clear"
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    
    // based on the settings get all the combos as one array, for later picking a
    // combo in the hit caller service
    func getPossibleCombos() -> [[Move]] {
        var kicksEnabled = false
        var dirtyEnabled = false
        var jumpingKicksEnabled = false
        var spinningKicksEnabled = false
        var dodgesEnabled = false
        var uppercutsEnabled = false
        var combosAvailable: [[Move]] = []
        
        do {
            // work out which guys are enabled first
            if let kicks = try settings.getValue(forKey: PossibleSetting.kicks.rawValue) as? String {
                kicksEnabled = (kicks == "1")
            }
            if let dirty = try settings.getValue(forKey: PossibleSetting.dirtyMoves.rawValue) as? String {
                dirtyEnabled = (dirty == "1")
            }
            if let jumpingKicks = try settings.getValue(forKey: PossibleSetting.jumpingKicks.rawValue) as? String {
                jumpingKicksEnabled = (jumpingKicks == "1")
            }
            if let spinningKicks = try settings.getValue(forKey: PossibleSetting.spinningKicks.rawValue) as? String {
                spinningKicksEnabled = (spinningKicks == "1")
            }
            if let dodges = try settings.getValue(forKey: PossibleSetting.dodgesAndCovers.rawValue) as? String {
                dodgesEnabled = (dodges == "1")
            }
            if let uppercuts = try settings.getValue(forKey: PossibleSetting.uppercuts.rawValue) as? String {
                uppercutsEnabled = (uppercuts == "1")
            }
            
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // now concatinated the moves into one final array and return it based on the settings
        combosAvailable += punches
        
        if (uppercutsEnabled) {
            combosAvailable += uppercuts
        }
        if (kicksEnabled) {
            combosAvailable += kicks
        }
        if (dirtyEnabled) {
            combosAvailable += dirty
        }
        if (dirtyEnabled && kicksEnabled) {
            combosAvailable += kicksAndDrity
        }
        if (kicksEnabled && jumpingKicksEnabled) {
            combosAvailable += jumpingKicks
        }
        if (kicksEnabled && spinningKicksEnabled) {
            combosAvailable += spinningKicks
        }
        if (dodgesEnabled) {
            combosAvailable += dodges
        }
        if (kicksEnabled && dodgesEnabled && spinningKicksEnabled) {
            combosAvailable += spinningKicksAndDodges
        }
        
        return combosAvailable
        
    }
}
