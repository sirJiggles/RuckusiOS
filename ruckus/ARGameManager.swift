//
//  ARGameManager.swift
//  ruckus
//
//  Created by Gareth on 19.02.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

protocol ControlsARGame {
    var hitCount: Int {
        get
    }
    var punchCount: Int {
        get
    }
    func increaseHitAmount() -> Void
    func increasePunchedAmount() -> Void
    func reset() -> Void
}

class ARGameManager: ControlsARGame {
    var hitCount: Int = 0
    var punchCount: Int = 0
    static let sharedInstance = ARGameManager()
    
    func reset() {
        hitCount = 0
        punchCount = 0
    }
    
    func increaseHitAmount() {
        hitCount += 1
    }
    func increasePunchedAmount() {
        punchCount += 1
    }
}
