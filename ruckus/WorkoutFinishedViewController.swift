//
//  WorkoutFinishedViewController.sift
//  ruckus
//
//  Created by Gareth on 28/03/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutFinishedViewController: UIViewController, WorkoutSummeryProtocol {
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var heartRate: UILabel!
    @IBOutlet weak var calories: UILabel!
    @IBOutlet weak var intervals: UILabel!
    @IBOutlet weak var hits: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var controlsClose: UIView!
    @IBOutlet weak var controlsSave: UIView!
    
    
    
    // rows for the heart rate and calories, if we get this data we will show
    @IBOutlet weak var calRow: UIView!
    @IBOutlet weak var heartRateRow: UIView!
    @IBOutlet weak var heartCalDivider: UIView!
    
    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
    let workoutSession = WorkoutSession.sharedInstance
    let timerController = IntervalTimer.sharedInstance
    let notificationBridge = WatchNotificationBridge.sharedInstance
    
    var soundPlayer: SoundPlayer?
    
    var summaryData: [String:String]?
    
    required init?(coder aDecoder: NSCoder) {
        soundPlayer = SoundPlayer()
        super.init(coder: aDecoder)
        workoutStoreHelper.summeryDelegate = self
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // listen to the ability to dismiss from watch
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.DismissFinishedScreenFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dismissFromWatch),
            name: NSNotification.Name(NotificationKey.DismissFinishedScreenFromWatch.rawValue),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // get the interval data from the instance of the timer
        let intervalsCount = timerController.intervalsDone
        
        // now we can stop the timer, we have the data we need (for intervals)
        timerController.stop()
        
        // hit data
        let hitsCalled = HitCaller.sharedInstance.hitsCalled
        if hitsCalled != 0 {
            hits.text = String(hitsCalled)
        }
        
        
        // if we already have summary data just use it
        if summaryData != nil {
            processWorkoutDataPayloadFromWatch()
            return
        }

        intervals.text = String(Int(intervalsCount))
        
        
        // get the workout data from the context
        let totals = workoutStoreHelper.getWorkoutTotals()
        if let calCount = totals["kCal"] {
            if calCount != 0 {
                calRow.isHidden = false
                calories.text = String(Int(calCount))
            }
        }
        
        var totalTime: Int
        
        if let startDate = workoutStoreHelper.workoutStartDate {
            totalTime = Int(Date().timeIntervalSince(startDate))
        } else {
            totalTime = 0
        }
        
        
        // convert the time to something we can display
        var timeMins = totalTime / 60
        let timeSeconds = totalTime % 60
        if timeMins > 60 {
            let timeHours = timeMins / 60
            timeMins = timeMins % 60
            time.text = String.localizedStringWithFormat("%2d:%02d:%02d", timeHours, timeMins, timeSeconds)
        } else {
            time.text = String.localizedStringWithFormat("%02d:%02d", timeMins, timeSeconds)
        }
        
        // check what controls we should show
        if !HKHealthStore.isHealthDataAvailable() {
            controlsClose.isHidden = false
            controlsSave.isHidden = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            try self.soundPlayer?.play("finished", withExtension: "wav")
        } catch {
            // do not throw an error here
//            fatalError(error.localizedDescription)
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // just incase the sound is still running!
        self.soundPlayer?.player.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Workout controller summary delegate functions
    func didSaveWorkout() {
        
        DispatchQueue.main.sync {
            self.saveButton.isEnabled = true
            self.saveButton.setTitle("Save", for: .normal)
            self.resetUI()
            self.presentingViewController?.dismiss(animated: false, completion: nil)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func couldNotSaveWorkout() {
        // @TODO build
    }
    
    // MARK: - listen to events from watch
    @objc func dismissFromWatch() {
        // discard local workout session at this stage, was saved on watch
        workoutSession.stop(andSave: false)
        dismiss(animated: true, completion: nil)
    }
    
    func processWorkoutDataPayloadFromWatch() {
        guard let data = summaryData else {
            fatalError("was no summary data to process")
        }
        // only if we get certain vals to we show certain fields
        if let heartRateText = data["heart"] {
            heartRateRow.isHidden = false
            heartRate.text = heartRateText
            heartCalDivider.isHidden = false
        }
        if let caloriesText = data["cal"] {
            calRow.isHidden = false
            calories.text = caloriesText
            heartCalDivider.isHidden = false
        }
        // should always get time and intervals
        if let intervalsText = data["interval"], let timeText = data["time"] {
            intervals.text = intervalsText
            time.text = timeText
        }
    }
    
    // MARK: - UI functions
    private func resetUI() {
        calRow.isHidden = true
        heartRateRow.isHidden = true
        time.text = "0:00"
        intervals.text = "0"
        heartRate.text = "0"
        calories.text = "0"
        summaryData = nil
    }
    
    // MARK: - IB Actions
    @IBAction func didTapDiscard(_ sender: Any) {
        resetUI()
        if (notificationBridge.sessionReachable()) {
            notificationBridge.sendMessage(.DismissFinishedScreenFromApp, callback: nil)
        } else {
            workoutSession.stop(andSave: false)
        }
        self.presentingViewController?.dismiss(animated: false, completion: nil)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        saveButton.isEnabled = false
        saveButton.setTitle("Saving ...", for: .normal)
        if (notificationBridge.sessionReachable()) {
            notificationBridge.sendMessage(.SaveFromFinishedScreenApp, callback: nil)
        } else {
            workoutSession.stop(andSave: true)
        }
    }
    
    
}
