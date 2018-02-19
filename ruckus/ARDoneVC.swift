//
//  ARDoneVC.swift
//  ruckus
//
//  Created by Gareth on 19.02.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import UIKit

class ARDoneVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var ctaHeight: NSLayoutConstraint!
    @IBOutlet weak var timesHit: UILabel!
    @IBOutlet weak var hitsDodged: UILabel!
    
    // MARK: - Lifecycle
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // update CTA buton sixe depending on device type
        if NotchUtils().hasSafeAreaInsets() {
            ctaHeight.constant = 90
        }
        
        // update label text on the totals
        timesHit.text = "\(ARGameManager.sharedInstance.punchCount)"
        hitsDodged.text = "\(ARGameManager.sharedInstance.hitCount)"
    }
    
    // MARK: - Actions
    @IBAction func tapClose(_ sender: Any) {
        ARGameManager.sharedInstance.reset()
        self.dismiss(animated: true, completion: nil)
    }
    
}
