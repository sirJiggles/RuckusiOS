//
//  StringCollectionTests.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import XCTest
@testable import ruckus

class StringCollectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringToTimeDouble() {
        XCTAssertEqual("01:60".stringTimeToDouble(), 120)
        XCTAssertEqual("1:60".stringTimeToDouble(), 120)
        XCTAssertEqual("1:0".stringTimeToDouble(), 60)
        XCTAssertEqual("1:00".stringTimeToDouble(), 60)
    }
    
    func testCammelCaseString() {
        XCTAssertEqual("ThingName".camelcaseString, "thingName")
        XCTAssertEqual("somethingCool".camelcaseString, "somethingCool")
        XCTAssertEqual("another thing".camelcaseString, "anotherThing")
    }
}
