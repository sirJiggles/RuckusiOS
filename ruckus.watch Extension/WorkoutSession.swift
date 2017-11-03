//
//  WorkoutSession.swift
//  ruckus
//
//  Created by Gareth on 21.05.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutSession: NSObject, HKWorkoutSessionDelegate, WorkoutManagerProtocol {
    let workoutStoreHelper = WorkoutStoreHelper.sharedInstance
    var currentSession: HKWorkoutSession?
    static let sharedInstance = WorkoutSession()
    var paused: Bool = false
    
    override init() {
        super.init()
        workoutStoreHelper.managerDelegate = self
    }
    
    // MARK: - HKWorkoutSessionDelegate functions
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
    // getting events from healthkit
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        switch toState {
        case .running:
            // just started a new workout
            if fromState == .notStarted || fromState == .ended {
                workoutStoreHelper.startAccumulatingData()
            } else {
                workoutStoreHelper.resumeAccumulatingData()
            }
        case .ended:
            workoutStoreHelper.stopAccumulatingData()
            workoutStoreHelper.saveWorkout()
        case.paused:
            workoutStoreHelper.pauseAccumulatingData()
        case.notStarted:
            break
        }
    }
    
    // MARK: - delegate functions from store helper
    func didStartWorkout(withConfiguration config: AnyObject) {
        do {
            let configuration = config as! HKWorkoutConfiguration
            currentSession = try HKWorkoutSession(configuration: configuration)
            currentSession?.delegate = self
            workoutStoreHelper.workoutStartDate = Date()
            
            workoutStoreHelper.store.start(currentSession!)
        } catch {
            fatalError("Could not start the workout, config was: \(config)")
        }
    }
    
    // MARK: - exposed functions for controlling workout sessions
    public func pause() {
        if paused {
            return
        }
        if let session = currentSession {
            paused = true
            workoutStoreHelper.store.pause(session)
        }
    }
    
    public func resume() {
        paused = false
        if let session = currentSession {
            workoutStoreHelper.store.resumeWorkoutSession(session)
        }
    }
    
    public func stop(andSave save: Bool) {
        paused = false
        workoutStoreHelper.saveSession = save
        workoutStoreHelper.endDate = Date()
        if let session = currentSession {
            workoutStoreHelper.store.end(session)
        }
    }
    
}
