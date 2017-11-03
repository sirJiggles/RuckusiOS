//
//  PickerController.swift
//  ruckus
//
//  Created by Gareth on 27.04.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit

// controller for all of the picker instances. Handle the updates to the settings etc
class PickerController {
    
    var possibleValues: [String] = []
    var settingsData: [String: AnyObject]
    var pickerKey: String?
    var storedValue: String?
    let settings: Settings
    var isSecondsPicker: Bool
    var isMinsPicker: Bool
    
    weak var delegate: WKInterfacePicker?
    
    init() {
        settings = Settings.init(usingPlist: "Settings")
        isSecondsPicker = false
        isMinsPicker = false
        do {
            settingsData = try settings.loadPlist()
        } catch {
            fatalError("Could not load defaults plist from picker watch")
        }
    }
    
    func reFetchData() {
        guard let key = pickerKey else {
            fatalError("no key set when trying to re-fetch picker data")
        }
        do {
            settingsData = try settings.loadPlist()
            storedValue = try settings.getValue(forKey: key) as? String
        } catch {
            fatalError("Could not load defaults plist for picker watch")
        }
    }
    
    // Util func for getting index of string slection
    func indexOfItem(_ item: String) -> Int? {
        // get index of value saved by user
        if let valueIndex = possibleValues.index(of: item) {
            let distance = possibleValues.distance(from: possibleValues.startIndex, to: valueIndex)
            return distance
        }
        
        return nil
    }
    
    
    // set the initial value of the picker
    func setInitialActive() {
        guard let key = pickerKey else {
            fatalError("There was no picker key set for the watch picker")
        }
        
        do {
            storedValue = try settings.getValue(forKey: key) as? String
        } catch let error {
            fatalError("\(error.localizedDescription)")
        }
        
        guard var storedValueString = storedValue else {
            return
        }
        
        // split the stored value if working with mins or seconds picker
        if isMinsPicker || isSecondsPicker {
            // split the current value into seconds and mins
            let parts = storedValueString.components(separatedBy: ":")
            
            if isSecondsPicker {
                storedValueString = parts[1]
            } else {
                // must be mins
                storedValueString = parts[0]
            }
        }
        
        if let index = indexOfItem(storedValueString) {
            delegate?.setSelectedItemIndex(index)
        }
    }

    // Get the data from the settings model and set it internally
    func setUpWithData(forKey key: String){
        
        pickerKey = key
        
        guard let data = settingsData[key] as! [String: AnyObject]?, let values = data["possibleValues"] as? [String] else {
            fatalError("Could not get the data for the picker")
        }
        
        possibleValues = values
        
        let dataForPicker = getPickerValues(using: values)
        
        delegate?.setItems(dataForPicker)
        
        setInitialActive()
    }
    
    // set up functions for mins and seconds
    func setUpWithSeconds(forKey key: String) {
        pickerKey = key
        isSecondsPicker = true
        // create an array of seconds to set
        var seconds:[String] = []
        for i in stride(from: 0, to: 60, by: 5) {
            if i < 10 {
                seconds.append("0\(i)")
            } else {
                seconds.append(String(i))
            }
        }
        possibleValues = seconds
        let dataForPicker = getPickerValues(using: seconds)
        delegate?.setItems(dataForPicker)
        
        setInitialActive()
    }
    
    func setUpWithMins(forKey key: String) {
        isMinsPicker = true
        pickerKey = key
        var mins: [String] = []
        for i in (0...20) {
            mins.append(String(i))
        }
        possibleValues = mins
        // create an array of mins to set
        let dataForPicker = getPickerValues(using: mins)
        delegate?.setItems(dataForPicker)
        
        setInitialActive()
    }
    
    func getPickerValues(using values: [Any]) -> [WKPickerItem] {
        let dataForPicker: [WKPickerItem] = values.map { (value) -> WKPickerItem in
            let pickerItem = WKPickerItem()
            let stringValue = value as? String ?? ""
            pickerItem.title = stringValue
            return pickerItem
        }
        return dataForPicker
    }
    
    
    func didPick(index: Int) {
        guard let key = pickerKey else {
            fatalError("No key set up on did pick event for watch picker")
        }
        
        var finalValueForSaving: String
        
        // if we are working with mins and seconds we need to stitch the value back together
        if isSecondsPicker || isMinsPicker {
            // have to refetch the data to make sure we have up to date stored values
            reFetchData()
            
            guard let storedValueString = storedValue else {
                fatalError("No Stored value set for picker on did pick event")
            }

            let parts = storedValueString.components(separatedBy: ":")
            
            if isSecondsPicker {
                finalValueForSaving = "\(parts[0]):\(possibleValues[index])"
            } else {
                finalValueForSaving = "\(possibleValues[index]):\(parts[1])"
            }
        } else {
            // just standard value
            finalValueForSaving = possibleValues[index]
        }
        
        settings.setValue(finalValueForSaving, forKey: key)
    }
    

}
