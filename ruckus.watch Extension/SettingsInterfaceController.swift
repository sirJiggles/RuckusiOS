//
//  SettingsInterfaceController.swift
//  ruckus
//
//  Created by Gareth on 27.04.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit
import Foundation


class SettingsInterfaceController: WKInterfaceController {
    
    var appNotificationBridge: AppNotificationBridge?
    
    @IBOutlet var intervalsPicker: WKInterfacePicker!
    @IBOutlet var intervalTime: WKInterfacePicker!
    @IBOutlet var intervalTimeSeconds: WKInterfacePicker!
    @IBOutlet var pauseTime: WKInterfacePicker!
    @IBOutlet var pauseTimeSeconds: WKInterfacePicker!
    @IBOutlet var preperationTime: WKInterfacePicker!
    @IBOutlet var preperationTimeSeconds: WKInterfacePicker!
    @IBOutlet var warmupTime: WKInterfacePicker!
    @IBOutlet var warmUpTimeSeconds: WKInterfacePicker!
    @IBOutlet var stretchingTime: WKInterfacePicker!
    @IBOutlet var stretchingTimeSeonds: WKInterfacePicker!
    @IBOutlet var voiceStylePicker: WKInterfacePicker!
    
    // picker managing classes
    let intervalPickerManager = PickerController()
    let intervalTimePickerManager = PickerController()
    let intervalTimeSecondsPickerManager = PickerController()
    let pauseTimePickerManager = PickerController()
    let pauseTimeSecondsPickerManager = PickerController()
    let preperationTimePickerManager = PickerController()
    let preperationTimeSecondsPickerManager = PickerController()
    let warmupTimePickerManager = PickerController()
    let warmupTimeSecondsPickerManager = PickerController()
    let stretchingTimePickerManager = PickerController()
    let stretchingTimeSecondsPickerManager = PickerController()
    let voiceStylePickerManager = PickerController()
    
    // toggles
    @IBOutlet var callOutHitsToggle: WKInterfaceSwitch!
    @IBOutlet var kicksToggle: WKInterfaceSwitch!
    @IBOutlet var jumpingKicksToggle: WKInterfaceSwitch!
    @IBOutlet var spinningKicksToggle: WKInterfaceSwitch!
    @IBOutlet var dirtyMovesToggle: WKInterfaceSwitch!
    @IBOutlet var dodgesToggle: WKInterfaceSwitch!
    
    var toggleControllers: [String: ToggleController] = [:]
    
    let callOutHitsToggleManager = ToggleController()
    let kicksToggleManager = ToggleController()
    let jumpingKicksToggleManager = ToggleController()
    let spinningKicksToggleManager = ToggleController()
    let dirtyMovesToggleManager = ToggleController()
    let dodgesToggleManager = ToggleController()
    
    // sliders
    @IBOutlet var difficultySlider: WKInterfaceSlider!
    @IBOutlet var volumeSlider: WKInterfaceSlider!
    
    let difficultySliderManager = SliderController()
    let volumeSliderManager = SliderController()
    
    
    // MARK: Lifecycle

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        DispatchQueue.global().sync {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.setAllValues),
                name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
                object: nil
            )
        }
        super.willActivate()
        
    }
    
    override func willDisappear() {
        // sync the settings before will leave
        let defaults = UserDefaults.standard.dictionaryRepresentation()
        appNotificationBridge?.sendMessageWithPayload(.UserDefaultsPayloadFromWatch, payload: defaults, callback: nil)
    }
    
    override func didAppear() {
        
        appNotificationBridge = AppNotificationBridge.sharedInstance
        
        setAllValues()
        
    }
    
    func setAllValues() {
        // set up all picker manager classes
        intervalPickerManager.delegate = intervalsPicker
        intervalPickerManager.setUpWithData(forKey: PossibleSetting.rounds.rawValue)
        
        intervalTimePickerManager.delegate = intervalTime
        intervalTimePickerManager.setUpWithMins(forKey: PossibleSetting.roundTime.rawValue)
        
        intervalTimeSecondsPickerManager.delegate = intervalTimeSeconds
        intervalTimeSecondsPickerManager.setUpWithSeconds(forKey: PossibleSetting.roundTime.rawValue)
        
        pauseTimePickerManager.delegate = pauseTime
        pauseTimePickerManager.setUpWithMins(forKey: PossibleSetting.pauseTime.rawValue)
        
        pauseTimeSecondsPickerManager.delegate = pauseTimeSeconds
        pauseTimeSecondsPickerManager.setUpWithSeconds(forKey: PossibleSetting.pauseTime.rawValue)
        
        preperationTimePickerManager.delegate = preperationTime
        preperationTimePickerManager.setUpWithMins(forKey: PossibleSetting.preperationTime.rawValue)
        
        preperationTimeSecondsPickerManager.delegate = preperationTimeSeconds
        preperationTimeSecondsPickerManager.setUpWithSeconds(forKey: PossibleSetting.preperationTime.rawValue)
        
        warmupTimePickerManager.delegate = warmupTime
        warmupTimePickerManager.setUpWithMins(forKey: PossibleSetting.warmUpTime.rawValue)
        
        warmupTimeSecondsPickerManager.delegate = warmUpTimeSeconds
        warmupTimeSecondsPickerManager.setUpWithSeconds(forKey: PossibleSetting.warmUpTime.rawValue)
        
        stretchingTimePickerManager.delegate = stretchingTime
        stretchingTimePickerManager.setUpWithMins(forKey: PossibleSetting.stretchTime.rawValue)
        
        stretchingTimeSecondsPickerManager.delegate = stretchingTimeSeonds
        stretchingTimeSecondsPickerManager.setUpWithSeconds(forKey: PossibleSetting.stretchTime.rawValue)
        
        voiceStylePickerManager.delegate = voiceStylePicker
        voiceStylePickerManager.setUpWithData(forKey: PossibleSetting.voiceStyle.rawValue)
        
        
        // toggles
        callOutHitsToggleManager.delegate = callOutHitsToggle
        callOutHitsToggleManager.setUp(forKey: PossibleSetting.callOutHits.rawValue)
        
        kicksToggleManager.delegate = kicksToggle
        kicksToggleManager.setUp(forKey: PossibleSetting.kicks.rawValue)
        
        jumpingKicksToggleManager.delegate = jumpingKicksToggle
        jumpingKicksToggleManager.setUp(forKey: PossibleSetting.jumpingKicks.rawValue)
        
        spinningKicksToggleManager.delegate = spinningKicksToggle
        spinningKicksToggleManager.setUp(forKey: PossibleSetting.spinningKicks.rawValue)
        
        dirtyMovesToggleManager.delegate = dirtyMovesToggle
        dirtyMovesToggleManager.setUp(forKey: PossibleSetting.dirtyMoves.rawValue)
        
        dodgesToggleManager.delegate = dodgesToggle
        dodgesToggleManager.setUp(forKey: PossibleSetting.dodgesAndCovers.rawValue)
        
        // array for sub disables logic
        toggleControllers[PossibleSetting.callOutHits.rawValue] = callOutHitsToggleManager
        toggleControllers[PossibleSetting.kicks.rawValue] = kicksToggleManager
        toggleControllers[PossibleSetting.jumpingKicks.rawValue] = jumpingKicksToggleManager
        toggleControllers[PossibleSetting.spinningKicks.rawValue] = spinningKicksToggleManager
        toggleControllers[PossibleSetting.dirtyMoves.rawValue] = dirtyMovesToggleManager
        toggleControllers[PossibleSetting.dodgesAndCovers.rawValue] = dodgesToggleManager
        
        // sliders
        difficultySliderManager.delegate = difficultySlider
        difficultySliderManager.setUp(forKey: PossibleSetting.difficulty.rawValue)
        
        volumeSliderManager.delegate = volumeSlider
        volumeSliderManager.setUp(forKey: PossibleSetting.volume.rawValue)
    }

    
    // MARK: Toggle related cell logic
    func disableEnableRelatedToggles(forToggle toggle: ToggleController, state: Bool) {
        
        // first toggle all the sub disables
        if let disables = toggle.disables {
            for toggleName in disables {
                if let subToggle = toggleControllers[toggleName] {
                    subToggle.setDisabledEnabled(state)
                    self.disableEnableRelatedToggles(forToggle: subToggle, state: state)
                }
            }
        }
        
    }
    
    // try to stop the warnings in xcode ... grrrrr
    override func pickerDidSettle(_ picker: WKInterfacePicker) {
        super.pickerDidSettle(picker)
    }
    
    override func pickerDidFocus(_ picker: WKInterfacePicker) {
        super.pickerDidFocus(picker)
    }
    
    override func pickerDidResignFocus(_ picker: WKInterfacePicker) {
        super.pickerDidResignFocus(picker )
    }
    
    
    // MARK: IBActions

    // pickers
    @IBAction func didPickIntervals(_ value: Int) {
        intervalPickerManager.didPick(index: value)
    }
    @IBAction func didPickIntervalTime(_ value: Int) {
        intervalTimePickerManager.didPick(index: value)
    }
    @IBAction func didPickIntervalsSeconds(_ value: Int) {
        intervalTimeSecondsPickerManager.didPick(index: value)
    }
    @IBAction func didPickPauseTime(_ value: Int) {
        pauseTimePickerManager.didPick(index: value)
    }
    @IBAction func didPickPauseTimeSeconds(_ value: Int) {
        pauseTimeSecondsPickerManager.didPick(index: value)
    }
    @IBAction func didPickPreperationTime(_ value: Int) {
        preperationTimePickerManager.didPick(index: value)
    }
    @IBAction func didPickPreperationTimeSeconds(_ value: Int) {
        preperationTimeSecondsPickerManager.didPick(index: value)
    }
    @IBAction func didPickWarmUpTime(_ value: Int) {
        warmupTimePickerManager.didPick(index: value)
    }
    @IBAction func didPickWarmUpTimeSeconds(_ value: Int) {
        warmupTimeSecondsPickerManager.didPick(index: value)
    }
    @IBAction func didPickStretchingTime(_ value: Int) {
        stretchingTimePickerManager.didPick(index: value)
    }
    @IBAction func didPickStretchingTimeSeconds(_ value: Int) {
        stretchingTimeSecondsPickerManager.didPick(index: value)
    }
    @IBAction func didPickVoiceStyle(_ value: Int) {
        voiceStylePickerManager.didPick(index: value)
    }
    
    // toggle actions
    @IBAction func didToggleCallOutHits(_ value: Bool) {
        callOutHitsToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: callOutHitsToggleManager, state: value)
    }
    @IBAction func didToggleKicks(_ value: Bool) {
        kicksToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: kicksToggleManager, state: value)
    }
    @IBAction func didToggleJumpingKicks(_ value: Bool) {
        jumpingKicksToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: jumpingKicksToggleManager, state: value)
    }
    @IBAction func didToggleSpinningKicks(_ value: Bool) {
        spinningKicksToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: spinningKicksToggleManager, state: value)
    }
    @IBAction func didToggleDirtyMoves(_ value: Bool) {
        dirtyMovesToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: dirtyMovesToggleManager, state: value)
    }
    @IBAction func didToggleDodges(_ value: Bool) {
        dodgesToggleManager.didToggle(value: value)
        disableEnableRelatedToggles(forToggle: dodgesToggleManager, state: value)
    }
    
    // slider actions
    @IBAction func didSlideDifficulty(_ value: Float) {
        difficultySliderManager.didSlide(to: value)
    }
    
    @IBAction func didSlideVolume(_ value: Float) {
        volumeSliderManager.didSlide(to: value)
    }
    
}
