//
//  SportModelTests.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import XCTest
@testable import ruckus

class SportModelTests: XCTestCase {
    var sportModal: Sport!
    
    override func setUp() {
        super.setUp()
        
        sportModal = Sport()
    }
    
    func testGetSportType() {
        let type = sportModal.getSportType(usingString: "HighIntensity")
        XCTAssertEqual(type, SportType.highIntensity)
    }
    
    func testGetSportIconForSportType() {
        let typeIcon = sportModal.icon(forSportType: SportType.boxing)
        XCTAssertEqual(typeIcon, #imageLiteral(resourceName: "boxing"))
    }
    
    func testGetSportForType() {
        let type = SportType.boxing
        let sportType = sportModal.getSport(forType: type)
        XCTAssertEqual(sportType, .boxing)
    }
    
    
}
