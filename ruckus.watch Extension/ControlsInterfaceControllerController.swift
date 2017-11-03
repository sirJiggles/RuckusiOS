//
//  ControlsInterfaceControllerController.swift
//  ruckus
//
//  Created by Gareth on 22.04.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import WatchKit
import Foundation


class ControlsInterfaceControllerController: WKInterfaceController, IntervalTimerStateChangeDelegate {
    
    var timer: IntervalTimer?
    
    // Mark: Outlets
    @IBOutlet var stopBtn: WKInterfaceButton!
    @IBOutlet var pauseBtn: WKInterfaceButton!
    @IBOutlet var playBtn: WKInterfaceButton!
    @IBOutlet var lockBtn: WKInterfaceButton!
    
    // Mark: Lifecycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }
    
    override func didAppear() {
        timer = IntervalTimer.sharedInstance
        setEnabledStateOfControlls()
        
        timer?.stateChangeDelegate = self
    }


    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: Delegate functions for the state events on the timer
    func didPlay() {
        stopBtn.setEnabled(true)
        stopBtn.setAlpha(1)
        lockBtn.setEnabled(true)
        lockBtn.setAlpha(1)
        pauseBtn.setEnabled(true)
        pauseBtn.setAlpha(1)
        pauseBtn.setHidden(false)
        playBtn.setEnabled(false)
        playBtn.setAlpha(0.4)
        playBtn.setHidden(true)
    }
    
    func didStop() {
        stopBtn.setEnabled(false)
        stopBtn.setAlpha(0.4)
        lockBtn.setEnabled(false)
        lockBtn.setAlpha(0.4)
        pauseBtn.setEnabled(false)
        pauseBtn.setAlpha(0.4)
        pauseBtn.setHidden(false)
        playBtn.setEnabled(false)
        playBtn.setAlpha(0.4)
        playBtn.setHidden(true)
    }
    
    func didPause() {
        stopBtn.setEnabled(true)
        stopBtn.setAlpha(1)
        lockBtn.setEnabled(true)
        lockBtn.setAlpha(1)
        pauseBtn.setEnabled(false)
        pauseBtn.setAlpha(0.4)
        pauseBtn.setHidden(true)
        playBtn.setEnabled(true)
        playBtn.setAlpha(1)
        playBtn.setHidden(false)
    }
    
    
    func setEnabledStateOfControlls() {
        
        if (timer?.running)! || (timer?.paused)! {
            stopBtn.setEnabled(true)
            stopBtn.setAlpha(1.0)
            lockBtn.setEnabled(true)
            lockBtn.setAlpha(1.0)
        } else {
            stopBtn.setEnabled(false)
            stopBtn.setAlpha(0.4)
            lockBtn.setEnabled(false)
            lockBtn.setAlpha(0.4)
        }
        
        if (timer?.running)! {

            if (timer?.paused)! {
                // show the play button as the timer is paused
                playBtn.setHidden(false)
                pauseBtn.setHidden(true)
            } else {
                pauseBtn.setEnabled(true)
                pauseBtn.setAlpha(1.0)
                pauseBtn.setHidden(false)
                playBtn.setHidden(true)
            }
            
        } else {
            // not running, disable, but show pause
            pauseBtn.setEnabled(false)
            pauseBtn.setAlpha(0.4)
            pauseBtn.setHidden(false)
            playBtn.setHidden(true)
        }
    }
    
    func reloadAllControllers(andPassContext context: String) {
        WKInterfaceController.reloadRootControllers(withNames: [ControllerNames.ControllsController.rawValue, ControllerNames.TimerController.rawValue, ControllerNames.SettingsController.rawValue], contexts: ["", context, ""])
    }
    
    // MARK: IB Actions
    @IBAction func tapStop() {
        reloadAllControllers(andPassContext: ControllerActions.Stop.rawValue)
    }
    
    @IBAction func tapPause() {
        reloadAllControllers(andPassContext: ControllerActions.Pause.rawValue)
    }
    
    @IBAction func tapPlay() {
        reloadAllControllers(andPassContext: ControllerActions.Play.rawValue)
    }
    

    @IBAction func tapLock() {
        // only load the timer interface controller as we want to lock the screen!
        WKInterfaceController.reloadRootControllers(withNames: [ControllerNames.TimerController.rawValue], contexts: [ControllerActions.Lock.rawValue])
    }
}
