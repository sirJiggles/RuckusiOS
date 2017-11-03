//
//  WorkoutSession.swift
//  ruckus
//
//  Created by Gareth on 21.05.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutSession: WorkoutManagerProtocol {
    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
    static let sharedInstance = WorkoutSession()
    
    init() {
        workoutStoreHelper.managerDelegate = self
    }
    
    var paused: Bool = false
    
    public func stop(andSave save: Bool) {
        paused = false
        workoutStoreHelper.saveSession = save
        workoutStoreHelper.endDate = Date()
        workoutStoreHelper.stopAccumulatingData()
        workoutStoreHelper.saveWorkout()
    }
    
    public func pause() {
        if paused {
            return
        }
        paused = true
        workoutStoreHelper.pauseAccumulatingData()
    }
    
    public func start() {
        if !paused {
            workoutStoreHelper.startAccumulatingData()
        } else {
            paused = false
            workoutStoreHelper.resumeAccumulatingData()
        }
    }
    
    public func resume() {
        if !paused {
            return
        }
        paused = false
        workoutStoreHelper.resumeAccumulatingData()
    }
    
    // MARK: - Workout manager delegate
    func didStartWorkout(withConfiguration: AnyObject) {
        workoutStoreHelper.workoutStartDate = Date()
        start()
    }
}
