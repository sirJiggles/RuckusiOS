//
//  VRRenderer.swift
//  ruckus
//
//  Created by Gareth on 04.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import Foundation

class VRRenderLoop: NSObject {
    let displayLink: CADisplayLink
    
    var paused = false {
        didSet {
            displayLink.isPaused = paused
        }
    }
    
    init(renderTarget:AnyObject,  selector: Selector) {
        displayLink = CADisplayLink.init(target: renderTarget, selector: selector)
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationWillResignActive(_ notification : Notification) {
        displayLink.isPaused = true;
    }
    
    
    @objc func applicationDidBecomeActive(_ notification : Notification) {
        displayLink.isPaused = paused;
    }
    
    func invalidate() {
        displayLink.invalidate();
    }

}
