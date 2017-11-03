//
//  SettingsModalTests.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import XCTest
@testable import ruckus

class SettingsModalTests: XCTestCase {
    
    var settingsModal: Settings!
    var settingsData: [String: AnyObject]!
    
    override func setUp() {
        
        // create an instance of settings and load it up using the
        // plist data
        settingsModal = Settings.init(usingPlist: "Settings")
        
        // reset user defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

        do {
            settingsData = try settingsModal.loadPlist()
        } catch {
            XCTFail("could not init the settings for settings modal tests")
        }
        
        super.setUp()
    }
    
    func testGetValueForKeyNoDefaultsSet() {
        do {
            let defaultVal = try settingsModal.getValue(forKey: PossibleSetting.rounds.rawValue)
            
            XCTAssertEqual(defaultVal as? String, "5")
        } catch {
            XCTFail("Could not get value for key from Plist")
        }
        
        // now try to get something we don't have in the plist
        XCTAssertThrowsError(_ = try settingsModal.getValue(forKey: "somethingNotFound"))
        
    }
    
    func testGetValueForKeyWithADefault() {
        // just set a value in the defaults
        settingsModal.setValue("4", forKey: PossibleSetting.rounds.rawValue)
        
        do {
            let setValue = try settingsModal.getValue(forKey: PossibleSetting.rounds.rawValue)
            
            XCTAssertEqual(setValue as? String, "4")
        } catch {
            XCTFail("Could not get user deafault set value for for key")
        }
    }
    
    func testGetEnabledDefault() {
        // HIIT does not have a toggle but we know there is one in the plist
        do {
            let defaultValue = try settingsModal.getEnabled(forKey: "callOutHits")
            XCTAssertEqual(defaultValue, true)
        } catch {
            XCTFail("could not get default value for call out hits")
        }
        
        // something we dont have
        XCTAssertThrowsError(_ = try settingsModal.getEnabled(forKey: "SomethingNotThere"))
    }
    
    func testGetEnabledUserDefaults() {
        settingsModal.setEnabled(false, forKey: "callOutHits")
        do {
            let setValue = try settingsModal.getEnabled(forKey: "callOutHits")
            XCTAssertFalse(setValue!)
        } catch {
            XCTFail("could not get set value for call out hits enabled")
        }
    }
    
    func testTypeOfCell() {
        let indexPath = IndexPath(row: 0, section: 0)
        let typeForIndex = settingsModal.typeOfCell(atIndexPath: indexPath)
        XCTAssertEqual(typeForIndex, CellType.selectCell)
    }
    
    func testKeyForCell(){
        let indexPath = IndexPath(row: 0, section: 0)
        let cellKey = settingsModal.keyForCell(atIndexPath: indexPath)
        XCTAssertEqual(cellKey, PossibleSetting.sport)
    }
    
    
    

}
