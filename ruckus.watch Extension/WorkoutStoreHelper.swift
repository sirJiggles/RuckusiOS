//
//  HKWorkouts.swift
//
//  Created by Gareth on 28/03/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import HealthKit
import UIKit

enum WorkoutErrors: Error {
    case CouldNotGetPermission
    case DeviceNotCapable
}

protocol WorkoutControllerProtocol: class {
    func didGetHeartRate(heartRate: UInt16) -> Void
    func didGetCalories(calories: Int) -> Void
}

protocol WorkoutSummeryProtocol: class {
    func didSaveWorkout() -> Void
}

protocol WorkoutManagerProtocol: class {
    func didStartWorkout(withConfiguration: AnyObject)
}

class WorkoutStoreHelper: NSObject {
    
    let store = HKHealthStore()
    var workoutStartDate: Date?
    var endDate: Date?
    var anchorQueries: [HKAnchoredObjectQuery] = []
    var delegate: WorkoutControllerProtocol?
    var summeryDelegate: WorkoutSummeryProtocol?
    var managerDelegate: WorkoutManagerProtocol?
    var isPaused: Bool = false
    let heartRateUnit = HKUnit(from: "count/min")
    
    var calCount: Double = 0
    var heartRateSamples: [Double] = []
    
    var config: AnyObject?
    var saveSession: Bool = false
    
    // use as a singleton
    static let sharedInstance = WorkoutStoreHelper()
    
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    public func startWorkout() {
        // create a configuration for the workout
        let workoutConfig = HKWorkoutConfiguration()
        
        // have to leave for cycling for now just to get dam calorie burn ...
        workoutConfig.activityType = .running
        workoutConfig.locationType = .indoor
    
        self.config = workoutConfig as HKWorkoutConfiguration
        
        managerDelegate?.didStartWorkout(withConfiguration: workoutConfig)
    }
    
    public func getAuth(completion:((_: Bool, _ err: Error?) -> Void)!) {
        
        // if not supported on device etc
        if (!HKHealthStore.isHealthDataAvailable()) {
            completion(false, WorkoutErrors.DeviceNotCapable)
            return
        }
        
        let readingData = Set(arrayLiteral:
            HKSampleType.quantityType(forIdentifier: .heartRate)!,
            HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        )
        
        let writingData = Set(arrayLiteral:
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        )
        
        store.requestAuthorization(toShare: writingData, read: readingData) { (result, err) in
            completion(result, err)
        }
    }
    
    // check if was previously authorized for when no phone connection and
    // running the first time on the watch
    public func wasPreviouslyAuthorised() -> HKAuthorizationStatus {
        // first check if we have authorization status already
        return store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
    }
    
    
    private func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { query, samples, deletedObjects, queryAnchor, error in
            self.processSamples(samples: samples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
            predicate: queryPredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler)
        
        
        query.updateHandler = updateHandler
        
        store.execute(query)
        
        anchorQueries.append(query)
    }

    
    public func getWorkoutTotals() -> [String: Double] {
        var totalHeartRate = 0.0
        if heartRateSamples.count > 0 {
            totalHeartRate = heartRateSamples.reduce(0, +)
        }
        var avgHeartRate = 0.0
        if totalHeartRate > 0.0 {
            avgHeartRate = totalHeartRate / Double(heartRateSamples.count)
        }
        
        return [
            "avgHeartRate": avgHeartRate,
            "kCal": calCount
        ]
    }
    
    public func saveWorkout() {
        let energy = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calCount)
        
        // reset
        calCount = 0
        heartRateSamples = []
        
        // only continue if user wanted to save the session
        if (!saveSession) {
            return
        }
        
        guard let configuration = self.config, let startDate = workoutStartDate else {
            fatalError("Could not get wourkout config or start date at end screen")
        }
        
        let isIndor = (configuration.locationType == .indoor) as NSNumber
        let workoutEndDate = endDate ?? Date()
        
        let workout = HKWorkout(
            activityType: configuration.activityType,
            start: startDate,
            end: workoutEndDate,
            duration: workoutEndDate.timeIntervalSince(startDate),
            totalEnergyBurned: energy,
            totalDistance: nil,
            metadata: [HKMetadataKeyIndoorWorkout: isIndor])
        
        // save the workout
        store.save(workout) { (sucess, error) in
            if (error != nil) {
                // @TODO this is where we try to save the workout later
                fatalError("Could not save the workout")
            }
            
            // add samples to the workout
            self.addSamplesToSavedWorkout(forWorkout: workout, withEndDate: workoutEndDate, andCalories: energy)
        }
        
    }
    
    private func addSamplesToSavedWorkout(forWorkout workout: HKWorkout, withEndDate endDate: Date, andCalories energy: HKQuantity) {
        
        guard let startDate = workoutStartDate else {
            return
        }
        // save the active energy burned sample
        let totalEnergyBurned = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            quantity: energy,
            start: startDate,
            end: endDate)
        
        let samples: [HKSample] = [
            totalEnergyBurned
        ]
        
        store.add(samples, to: workout) { (sucess, error) in
            if (error != nil) {
                fatalError("Could not add the HK samples to the workout")
            }
            // should let the delegate know that the workout has now been saved
            self.summeryDelegate?.didSaveWorkout()
        }
    }
    
    
    // MARK: logic for getting sample data, pausing sample data and resuming etc
    
    // start getting data samples when we start a workout
    func startAccumulatingData() {
        // start queries for what we want to show on the watch face
        startQuery(quantityTypeIdentifier: .activeEnergyBurned)
        startQuery(quantityTypeIdentifier: .heartRate)
    }
    
    func pauseAccumulatingData() {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    func resumeAccumulatingData() {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    func stopAccumulatingData() {
        for query in anchorQueries {
            store.stop(query)
        }
        isPaused = false
        anchorQueries.removeAll()
    }
    
    // MARK: - Processing data
    
    // the func to process the samples from the hk store
    func processSamples(samples: [HKSample]?, quantityTypeIdentifier: HKQuantityTypeIdentifier) -> Void {
        
        if isPaused { return }
        guard let theSamples = samples as? [HKQuantitySample] else { return }
        guard let sample = theSamples.first else{ return }
        
        
        DispatchQueue.main.async { [weak self] in
            switch quantityTypeIdentifier {
            case HKQuantityTypeIdentifier.heartRate:
                let value = sample.quantity.doubleValue(for: (self?.heartRateUnit)!)
                self?.delegate?.didGetHeartRate(heartRate: UInt16(value))
                // store the heart rate samples for the average call at the end
                self?.heartRateSamples.append(value)
                break
            case HKQuantityTypeIdentifier.activeEnergyBurned:
                let cal = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                print(cal)
                self?.calCount += ceil(cal)
                if let calCount = self?.calCount {
                    self?.delegate?.didGetCalories(calories: Int(calCount))
                }
                break
            default:
                return
            }
            
        }

    }
    
    

}
