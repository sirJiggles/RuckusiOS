//
//  FirstViewController.swift
//  ruckus
//
//  Created by Gareth on 01/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import MKRingProgressView
import HealthKit

class TimerViewController: TimableController, TimableVCDelegate {
    var ringCurrent: Double = 0.0
    var roundIcons: [UIView] = []
    
    @IBOutlet weak var timeSectionView: UIView!
    @IBOutlet weak var ring: MKRingProgressView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var modeLabel: UILabel!
    
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseStopContainer: UIView!
    
    // this is what we insert the round marks into
    @IBOutlet weak var roundsContainer: UIView!
    
    // MARK: - View life cycle
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the size of the rings and spacing for larger screens
        ring.progress = 0
        
        // iPadPro 12: 1024.0
        // iPadPro 9.7 / iPadAir / iPadAir2: 768.0
        let size = UIScreen.main.bounds
        
        calcAndSetRingSize(width: size.width, height: size.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timerVCDelegate = self
    }
    
    override func viewDidLayoutSubviews() {
        setUpRoundIcons()
    }
    
    // will go into various rotation modes in iPad large portrait
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.calcAndSetRingSize(width: size.width, height: size.height)
        }) { (context) in
            // after, if we need to clean anything up, dont think we will though
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Timer VC delegate hooks

    func settingsSyncUI() {
        // might also need to update the rounds area (in main thread)
        DispatchQueue.main.async {
            self.setUpRoundIcons()
        }
    }
    
    func didTickUISecond(time: String, mode: TimerMode) {
        DispatchQueue.main.async {
            self.timeLabel.text = time
        }
    }

    func tick(newValue: Double) -> Void {
        // update the ring, always
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        ring.progress = newValue
        CATransaction.commit()
        ringCurrent = newValue
    }
    
    func updateCircuitNumberUI(to newValue: Double, circuitNumber: Int) {
        if roundIcons.indices.contains(circuitNumber - 1) {
            roundIcons[circuitNumber - 1].backgroundColor = UIColor.white
        }
    }
    
    // when done the workout
    func finnishedUI() {
        showPlayButton()
    }
    
    func setUpSwitchModesUI() {
        timeLabel.text = "00:00"
        switch (timer.currentMode) {
        case .preparing:
            modeLabel.text = "Prepare"
        case .resting:
            modeLabel.text = "Resting"
        case .stretching:
            modeLabel.text = "Stretch"
        case .warmup:
            modeLabel.text = "Warmup"
        case .working:
            modeLabel.text = "Working"
        }
            
    }
    
    func setColours() {
        switch (timer.currentMode) {
        case .preparing:
            modeLabel.textColor = UIColor.lightGreen
            timeLabel.textColor = UIColor.lightGreen
        case .resting, .stretching:
            modeLabel.textColor = UIColor.lightestBlue
            timeLabel.textColor = UIColor.lightestBlue
        case .working, .warmup:
            modeLabel.textColor = UIColor.theOrange
            timeLabel.textColor = UIColor.theOrange
        }
    }
    
    // reset the rings
    func didStartUI() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        self.ring.progress = 0
        CATransaction.commit()
    }
    
    func resetUI() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = 0
        CATransaction.commit()
        ringCurrent = 0
        timeLabel.text = "00:00"
        timeLabel.textColor = UIColor.greyOne
        modeLabel.isHidden = true
        // reset the colors for the icons
        for icon in roundIcons {
            icon.backgroundColor = UIColor.greyOne
        }
    }
    
    func startWorkoutUI() {
        timeLabel.textColor = UIColor.theOrange
        modeLabel.textColor = UIColor.theOrange
        hidePlayButton()
        modeLabel.isHidden = false
    }
    
    func stopWorkoutUI() {
        showPlayButton()
    }
    
    func pauseWorkoutUI() {
        showPlayButton()
    }
    
    func didFinishPlayingCombo() {
        // do nothing
    }
    
    
    // MARK: - View functions like clicking buttons
    func repositionAmbiguous() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = ringCurrent + 1
        CATransaction.commit()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        ring.progress = ringCurrent
        CATransaction.commit()
    }
    
    func calcAndSetRingSize(width: CGFloat, height: CGFloat) {
        
        switch (width, height) {
        // 12.9 inch iPad port
        case (let w, let h) where w == 1024.0 && h == 1366.0:
            ring.ringWidth = 70
            timeLabel.font = UIFont(name: "Impact", size: 300)
            modeLabel.font = UIFont(name: "Impact", size: 60)
            setUpRoundIcons()
            break
        // 12.9 inch iPad, land
        case (let w, let h) where h == 1024.0 && w == 1366.0:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 10.5 inch iPad port
        case (let w, let h) where h == 1112.0 && w == 834.0:
            timeLabel.font = UIFont(name: "Impact", size: 200)
            modeLabel.font = UIFont(name: "Impact", size: 55)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 10.5 inch iPad land
        case (let w, let h) where h == 834.0 && w == 1112.0:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            ring.ringWidth = 50
            break
        // 9.7 inch iPad port
        case (let w, let h) where w == 768.0 && h == 1024.0:
            ring.ringWidth = 50
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            break
        // 9.7 inch iPad land
        case (let w, let h) where h == 768.0 && w == 1024.0:
            timeLabel.font = UIFont(name: "Impact", size: 155)
            modeLabel.font = UIFont(name: "Impact", size: 45)
            ring.ringWidth = 35
            setUpRoundIcons()
            break
        // 6 / 7 +
        case (let w, _) where w == 414:
            ring.ringWidth = 34
            timeLabel.font = UIFont(name: "Impact", size: 150)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            break
        // 6 / 7
        case (let w, _) where w == 375:
            ring.ringWidth = 28
            timeLabel.font = UIFont(name: "Impact", size: 130)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            break
        // 5 and bellow
        case (_, let h) where h <= 568:
            ring.ringWidth = 25
            timeLabel.font = UIFont(name: "Impact", size: 110)
            modeLabel.font = UIFont(name: "Impact", size: 25)
            break
        // some default font size handling for saftey
        case (let w, _) where w >= 700:
            timeLabel.font = UIFont(name: "Impact", size: 180)
            modeLabel.font = UIFont(name: "Impact", size: 50)
            setUpRoundIcons()
            repositionAmbiguous()
            break
        default:
            timeLabel.font = UIFont(name: "Impact", size: 130)
            modeLabel.font = UIFont(name: "Impact", size: 40)
            setUpRoundIcons()
            repositionAmbiguous()
            break
        }

    }
    
    // create the icons for the rounds
    func setUpRoundIcons() {
        // now we need to remove all the icons that may have already been there
        for icon in roundIcons {
            icon.removeFromSuperview()
        }
        // clear out the array
        roundIcons = []
        
        var amountOfRounds = timer.intervals
        let segmentSize = Double(roundsContainer.frame.width) / amountOfRounds
        let maxHeight = Double(roundsContainer.frame.height / 2)
        var height = segmentSize + (segmentSize * 0.3)
        height = (height > maxHeight) ? maxHeight : height
        let yPos = (Double(roundsContainer.frame.midY) - (height / 2))
        let space = 5.0
        let cornerSize = segmentSize / amountOfRounds
        let cornerRadius = CGFloat((cornerSize > 5) ? 5 : cornerSize)
        // start the x off at 10 from the left of the container
        var previousX = 0.0
        
        while amountOfRounds > 0 {
            // create a new view for each round
            let size = CGSize(width: segmentSize - space, height: height)
            // put the x is in the right place and add it in the middle of the view
            let origin = CGPoint(x: CGFloat(previousX), y: CGFloat(yPos))
            let frame = CGRect(origin: origin, size: size)
            let view = UIView(frame: frame)
            view.layer.cornerRadius = cornerRadius
            view.backgroundColor = UIColor.greyOne
            // add the view to our array so we can mark it as complete
            roundIcons.append(view)
            roundsContainer.addSubview(view)
            previousX = (previousX + segmentSize)
            amountOfRounds = amountOfRounds - 1
        }
        
        // update the color of the rounds that are done, incase we removed them by mistake
        var amountDone = Int(timer.intervalsDone)
        while amountDone > 0 {
            roundIcons[amountDone - 1].backgroundColor = UIColor.white
            amountDone = amountDone - 1
        }
    }
    
    
    func hidePlayButton() {
        playBtn.isHidden = true
        pauseStopContainer.isHidden = false
    }
    
    func showPlayButton() {
        playBtn.isHidden = false
        pauseStopContainer.isHidden = true
    }
    
    
    // interacting with buttons
    @IBAction func clickPause(_ sender: Any) {
        let pauseTime = NSDate()
        if let timer = comboTimer {
            timer.invalidate()
        }
        if (notificationBridge.sessionReachable()) {
            notificationBridge.sendMessageWithPayload(.PauseWorkoutFromApp, payload: ["pauseTime":pauseTime], callback: nil)
        } else {
            workoutSession.pause()
        }
        do {
            try self.soundPlayer.play("pause", withExtension: "wav")
        } catch let error {
            fatalError(error.localizedDescription)
        }
        pauseWorkout(pauseTime)
    }
    
    @IBAction func clickStop(_ sender: Any) {
        if let timer = comboTimer {
            timer.invalidate()
        }
        if notificationBridge.sessionReachable() {
            stopWorkout()
            notificationBridge.sendMessage(NotificationKey.StopWorkoutFromApp, callback: nil)
        } else {
            guard let workoutStartDate = workoutStoreHelper.workoutStartDate else {
                stopWorkout()
                workoutSession.stop(andSave: false)
                return
            }
            
            if Date().timeIntervalSince(workoutStartDate) > 20.0 {
                resetUI()
                
                // but still kill the crowed in this case
                stopCrowd()
                
                // just pause the timer for now, it WILL be stopped on the other screen
                pauseWorkoutTimer()
                // show the finished screen
                performSegue(withIdentifier: "workoutFinishedFromTimer", sender: nil)
            } else {
                stopWorkout()
                workoutSession.stop(andSave: false)
            }
        }
    }
    
    @IBAction func clickPlay(_ sender: Any) {
        proceedWithPlayClick()
    }
    
}

