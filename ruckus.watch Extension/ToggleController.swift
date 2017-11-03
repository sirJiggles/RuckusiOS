//
//  toggleController.swift
//  ruckus
//
//  Created by Gareth on 01.05.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit

class ToggleController {
    let settingsData: [String: AnyObject]
    var toggleKey: String?
    let settings: Settings
    var disables: [String]?
    
    weak var delegate: WKInterfaceSwitch?
    
    init() {
        settings = Settings.init(usingPlist: "Settings")
        do {
            settingsData = try settings.loadPlist()
        } catch {
            fatalError("Could not load defaults plist from picker watch")
        }
    }
    
    func setUp(forKey key: String) {
        toggleKey = key
        
        guard let data = settingsData[key] as! [String: AnyObject]? else {
            fatalError("Could not get the data for the toggle")
        }
        
        self.disables = data["disables"] as? [String]
        
        let storedValue: String
        let storedEnabled: Bool
        
        do {
            storedValue = try settings.getValue(forKey: key) as! String
            storedEnabled = try settings.getEnabled(forKey: key)!
        } catch let error {
            fatalError("\(error)")
        }
        
        delegate?.setOn((storedValue == "1") ? true : false)
        delegate?.setEnabled(storedEnabled)
    }
    
    func setDisabledEnabled(_ state: Bool) {
        delegate?.setEnabled(state)
        settings.setEnabled(state, forKey: toggleKey!)
    }
    
    func didToggle(value: Bool) {
        let newValue: String = (value) ? "1" : "0"
        settings.setValue(newValue, forKey: toggleKey!)
    }

}
