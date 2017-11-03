//
//  StepperController.swift
//  ruckus
//
//  Created by Gareth on 01.05.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit

class SliderController {
    let settingsData: [String: AnyObject]
    var sliderKey: String?
    let settings: Settings
    
    weak var delegate: WKInterfaceSlider?
    
    init() {
        settings = Settings.init(usingPlist: "Settings")
        do {
            settingsData = try settings.loadPlist()
        } catch {
            fatalError("Could not load defaults plist from picker watch")
        }
    }
    
    func setUp(forKey key: String) {
        sliderKey = key
        
        let storedValue: Float
        
        do {
            storedValue = try settings.getValue(forKey: key) as! Float
        } catch let error {
            fatalError("\(error)")
        }
        
        delegate?.setValue(storedValue * 10)
    }
    
    func didSlide(to value: Float) {
        settings.setValue(value / 10, forKey: sliderKey!)
    }
    
}
