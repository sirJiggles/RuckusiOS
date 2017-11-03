//
//  NotificationKeys.swift
//  ruckus
//
//  Created by Gareth on 01/04/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

enum NotificationKey: String {
    case StartWorkoutFromWatch
    case PauseWorkoutFromWatch
    case StopWorkoutFromWatch
    case StartWorkoutFromApp
    case PauseWorkoutFromApp
    case StopWorkoutFromApp
    case UserDefaultsPayloadFromApp
    case UserDefaultsPayloadFromWatch
    case RequestUserDefaultsFromWatch
    case RequestUserDefaultsFromApp
    case PauseFromWatchControlsPage
    case StopFromWatchControlsPage
    case LockFromWatchControlsPage
    case DismissFinishedScreenFromApp
    case SaveFromFinishedScreenApp
    case DismissFinishedScreenFromWatch
    case WorkoutSummaryFromWatch
    case ShowFinishedScreenFromWatch
    case SwitchModesFromWatch
    case SettingsSync
    
    // cases for in app purchases
    case StartedPayment
    case FailedPayment
    case PaymentSuccess
    case CouldNotRestore
}
