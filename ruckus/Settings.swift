//
//  Settings.swift
//  ruckus
//
//  Created by Gareth on 12/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

enum SettingsModelError: Error {
    case CouldNotGetValue
    case CouldNotGetEnabled
}

enum PossibleSetting: String {
    case location
    case rounds
    case roundTime
    case pauseTime
    case preperationTime
    case callOutHits
    case voiceStyle
    case kicks
    case jumpingKicks
    case spinningKicks
    case dirtyMoves
    case dodgesAndCovers
    case difficulty
    case volume
    case warmUpTime
    case stretchTime
    case volumeButton
    case uppercuts
    case backgroundCrowd
    case userHeight
    case model
    case showRing
}

enum CellType: String {
    case toggleCell
    case selectCell
    case selectCellTime
    case difficultyCell
    case scrollCell
    case buttonCell
    case volumeCell
    case numberCell
}

class Settings {
    var defaultsAccessor: UserDefaultsHelper
    var plistAccessor: PlistHelper
    // used for if there are no user defaults
    var defaultsPlist: [String: AnyObject]
    
    init(usingPlist resource: String) {
        self.defaultsAccessor = UserDefaultsHelper()
        self.plistAccessor = PlistHelper.init(resource: resource)
        self.defaultsPlist = [:]
    }
    
    func initPlist() throws {
        let plist = try self.plistAccessor.getPlist()
        self.defaultsPlist = plist
    }
    
    func loadPlist() throws -> [String: AnyObject] {
        try self.initPlist()
        return self.defaultsPlist
    }
    
    func indexPathForToggle(forSetting key: PossibleSetting) -> IndexPath {
        var row: Int
        switch key {
        case .backgroundCrowd:
            row = 1
        case .voiceStyle:
            row = 2
        case .uppercuts:
            row = 3
        case .kicks:
            row = 4
        case .jumpingKicks:
            row = 5
        case .spinningKicks:
            row = 6
        case .dirtyMoves:
            row = 7
        case .dodgesAndCovers:
            row = 8
        default:
            row = 0
        }
        
        return IndexPath(row: row, section: 1)
    }
    
    func getValue(forKey key: String) throws -> Any? {
        // try first get it from the user defaults
        if let value = self.defaultsAccessor.getValue(forKey: key) {
            return value
        }
        
        // check if we have the key in the deafults
        if let valueFromInternalPlist = self.defaultsPlist[key]?["value"] {
            return valueFromInternalPlist
        } else {
            throw SettingsModelError.CouldNotGetValue
        }
        
    }
    
    func setValue(_ value: Any, atIndexPath indexPath: IndexPath) {
        let key = self.keyForCell(atIndexPath: indexPath)
        self.defaultsAccessor.setValue(value, forKey: key.rawValue)
    }
    
    func setValue(_ value: Any, forKey key: String) {
        self.defaultsAccessor.setValue(value, forKey: key)
    }
    
    func getEnabled(forKey key: String) throws -> Bool? {
        // try first get it from the user defaults
        if let enabled = self.defaultsAccessor.getValue(forKey: "\(key)-enabled") {
            return enabled as? Bool
        }
        
        // check if we have the key in the deafults
        if let enabledFromInternalPlist = self.defaultsPlist[key]?["enabled"] {
            return enabledFromInternalPlist as? Bool
        } else {
            throw SettingsModelError.CouldNotGetEnabled
        }
    }
    
    func setEnabled(_ value: Bool, atIndexPath indexPath: IndexPath) {
        let key = self.keyForCell(atIndexPath: indexPath)
        self.defaultsAccessor.setValue(value, forKey: "\(key.rawValue)-enabled")
    }
    
    func setEnabled(_ value: Bool, forKey key: String) {
        self.defaultsAccessor.setValue(value, forKey: "\(key)-enabled")
    }
    
    // Map the type of cells for the indexes in the table view
    func typeOfCell(atIndexPath indexPath: IndexPath) -> CellType {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return .selectCell
            default:
                return .selectCellTime
            }
        case 1:
            switch indexPath.row {
            case 0:
                return .toggleCell
            case 2:
                return .selectCell
            default:
                return .toggleCell
            }
        case 2:
            return .difficultyCell
        case 3:
            switch indexPath.row {
            case 0:
                return .scrollCell
            default:
                return .volumeCell
            }
        case 4:
            return .numberCell
        case 5:
            switch indexPath.row {
            case 0:
                return .selectCell
            default:
                return .toggleCell
            }
        case 6:
            return .buttonCell
        default:
            return .toggleCell
        }
    }
    
    
    // map the settings key for the cell
    func keyForCell(atIndexPath indexPath: IndexPath) -> PossibleSetting {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            return .rounds
        case (0,1):
            return .roundTime
        case (0,2):
            return .pauseTime
        case (0,3):
            return .preperationTime
        case (0,4):
            return .warmUpTime
        case (0,5):
            return .stretchTime
        case (1,0):
            return .callOutHits
        case (1,1):
            return .backgroundCrowd
        case (1,2):
            return .voiceStyle
        case (1,3):
            return .uppercuts
        case (1,4):
            return .kicks
        case (1,5):
            return .jumpingKicks
        case (1,6):
            return .spinningKicks
        case (1,7):
            return .dirtyMoves
        case (1,8):
            return .dodgesAndCovers
        case (2,0):
            return .difficulty
        case (3,0):
            return .volume
        case (3,1):
            // this key does nothing with regards to settings
            return .volumeButton
        case (4,0):
            return .userHeight
        case (5,0):
            return .model
        case (5,1):
            return .showRing
        default:
            return .callOutHits
        }
    }
    
}

