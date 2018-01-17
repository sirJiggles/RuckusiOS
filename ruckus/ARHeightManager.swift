//
//  ARHeightManager.swift
//  manages the height of the standing position of the user by using the avarage
//  from x frames
//  ruckus
//
//  Created by Gareth on 16.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

protocol GetsAverageHeight {
    var frames: [Float] { get }
    func insert(height: Float) -> Void
    func getAverage() -> Float
}

class ARHeightManager: GetsAverageHeight {
    var frames: [Float] = []
    private let maxFrames: Int = 60
    
    func insert(height: Float) {
        if frames.count > maxFrames {
            frames.remove(at: 0)
        }
        frames.append(height)
    }
    
    // returns the average height from all the frames at the moment
    func getAverage() -> Float {
        let sumArray = frames.reduce(0, +)
        return sumArray / Float(frames.count)
    }
}
