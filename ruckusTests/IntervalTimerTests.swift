//
//  IntervalTimerTests.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import XCTest
@testable import ruckus

class IntervalTimerTests: XCTestCase {
    var timer: IntervalTimer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        timer = IntervalTimer.sharedInstance
        // set all to one second
        timer.prepTime = 1.0
        timer.restTime = 1.0
        timer.intervals = 2
        timer.intervalTime = 1.0
        timer.warmupTime = 1.0
        timer.stretchTime = 1.0
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGreenPathForAllModes() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        
        timer.start(NSDate())
        
        XCTAssertEqual(timer.currentMode, .warmup)
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .stretching)
        }
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .preparing)
        }
        Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .working)
        }
        Timer.scheduledTimer(withTimeInterval: 9, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .resting)
            XCTAssertEqual(self.timer.intervalsDone, 1)
            self.timer.stop()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testNoWarmUp() {
        timer.warmupTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .stretching)
        timer.stop()
    }
    
    func testNoStretchingbutWarmup() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        timer.stretchTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .warmup)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .preparing)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func testNoStretchOrWarmup() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        timer.stretchTime = 0.0
        timer.warmupTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .preparing)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .working)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func testNoPrepNoWarmupAndNoStretch() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        timer.stretchTime = 0.0
        timer .warmupTime = 0.0
        timer.prepTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .working)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .resting)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func testWarmupNoStretchNoPrep() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        timer.stretchTime = 0.0
        timer.prepTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .warmup)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .working)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func testStretchAndPrepNoWarmup() {
        let expectation = XCTestExpectation(description: "wait for all the different modes")
        timer.warmupTime = 0.0
        timer.start(NSDate())
        XCTAssertEqual(timer.currentMode, .stretching)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .preparing)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }
    
    func testPauseFunctionality() {
        let expectation = XCTestExpectation(description: "wait for all the things")
        timer.start(NSDate())
        timer.pause(NSDate())
        XCTAssertEqual(timer.currentMode, .warmup)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            self.timer.start(NSDate())
        }
        Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .stretching)
            self.timer.pause(NSDate())
        }
        Timer.scheduledTimer(withTimeInterval: 9, repeats: false) { _ in
            self.timer.start(NSDate())
        }
        Timer.scheduledTimer(withTimeInterval: 12, repeats: false) { _ in
            XCTAssertEqual(self.timer.currentMode, .preparing)
            self.timer.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 13)
    }
    
}
