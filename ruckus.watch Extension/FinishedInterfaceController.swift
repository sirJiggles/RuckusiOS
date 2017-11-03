//
//  FinishedInterfaceController.swift
//  ruckus
//
//  Created by Gareth on 14.05.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit
import Foundation


class FinishedInterfaceController: WKInterfaceController, WorkoutSummeryProtocol {
    
    // MARK: - IBOutlets
    @IBOutlet var intervalTimeLabel: WKInterfaceLabel!
    @IBOutlet var intervalsLabel: WKInterfaceLabel!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var hitsLabel: WKInterfaceLabel!
    @IBOutlet var KcalLabel: WKInterfaceLabel!
    
    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
    let timerController = IntervalTimer.sharedInstance
    let workoutSession = WorkoutSession.sharedInstance
    let appNotificationBridge = AppNotificationBridge.sharedInstance
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        DispatchQueue.global().async {
            // listen to the ability to dismiss from watch
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name(NotificationKey.DismissFinishedScreenFromApp.rawValue),
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.dismissFromApp),
                name: NSNotification.Name(NotificationKey.DismissFinishedScreenFromApp.rawValue),
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name(NotificationKey.SaveFromFinishedScreenApp.rawValue),
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.saveFromApp),
                name: NSNotification.Name(NotificationKey.SaveFromFinishedScreenApp.rawValue),
                object: nil
            )
        }
        
        workoutStoreHelper.summeryDelegate = self
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        var appPayload:[String:String] = [:]
        
        // get the workout data from the context
        let totals = workoutStoreHelper.getWorkoutTotals()
        if let heartRate = totals["avgHeartRate"], let calCount = totals["kCal"] {
            let heartRateText = String(UInt16(heartRate))
            let calText = String(Int(calCount))
            heartRateLabel.setText(heartRateText)
            KcalLabel.setText(calText)
            
            appPayload["heart"] = heartRateText
            appPayload["cal"] = calText
        }
        
        // get the interval data from the instance of the timer
        let intervals = timerController.intervalsDone
        
        // now we can stop the timer, we have the data we need
        timerController.stop()
        
        guard let startDate = workoutStoreHelper.workoutStartDate else {
            fatalError("Could not calculate workout time")
        }
        
        let totalTime = Int(Date().timeIntervalSince(startDate))
        
        
        // convert the time to something we can display
        var timeMins = totalTime / 60
        let timeSeconds = totalTime % 60
        var timeString = ""
        if timeMins > 60 {
            let timeHours = timeMins / 60
            timeMins = timeMins % 60
            timeString = String.localizedStringWithFormat("%2d:%02d:%02d", timeHours, timeMins, timeSeconds)
            intervalTimeLabel.setText(timeString)
        } else {
            timeString = String.localizedStringWithFormat("%02d:%02d", timeMins, timeSeconds)
            intervalTimeLabel.setText(timeString)
        }
        
        appPayload["time"] = timeString
        
        let intervalText = String(Int(intervals))
        intervalsLabel.setText(intervalText)
        
        // send the workout data to the app for showing
        appPayload["interval"] = intervalText
        
        // show the finished screen call with the workout data to pass along the context
        if appNotificationBridge.sessionReachable() {
            appNotificationBridge.sendMessageWithPayload(.ShowFinishedScreenFromWatch, payload: appPayload, callback: nil)
        }
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: - Workout controller summery delegate functions
    func didSaveWorkout() {
        resetUI()
        showTimer()
        appNotificationBridge.sendMessage(.DismissFinishedScreenFromWatch, callback: nil)
    }
    
    func couldNotSaveWorkout() {
        // @TODO build
    }
    
    // MARK: - App bridge functions for interacting with the finished screen
    @objc func dismissFromApp() {
        resetUI()
        workoutSession.stop(andSave: false)
        showTimer()
    }
    
    @objc func saveFromApp() {
        workoutSession.stop(andSave: true)
    }
    
    // MARK: - UI functions
    private func resetUI() {
        intervalTimeLabel.setText("0:00")
        intervalsLabel.setText("0")
        heartRateLabel.setText("0")
        KcalLabel.setText("0")
    }
    
    @objc private func showTimer() {
        WKInterfaceController.reloadRootControllers(withNames: [ControllerNames.ControllsController.rawValue, ControllerNames.TimerController.rawValue, ControllerNames.SettingsController.rawValue], contexts: ["", ControllerActions.Unlock.rawValue, ""])
    }
    
    // MARK: - IBActions
    @IBAction func tapSave() {
        // save the workout and return to the main controller
        workoutSession.stop(andSave: true)
    }
    
    @IBAction func tapDiscard() {
        resetUI()
        workoutSession.stop(andSave: false)
        showTimer()
        if appNotificationBridge.sessionReachable() {
            appNotificationBridge.sendMessage(.DismissFinishedScreenFromWatch, callback: nil)
        }
    }

}
