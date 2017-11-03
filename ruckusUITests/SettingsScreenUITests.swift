//
//  SettingsScreenUITests.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import XCTest

class SettingsScreenUITests: XCTestCase {
    
    var app: XCUIApplication!
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // go to the settings page
        app = XCUIApplication()
        
        // needed to reset user defaults
        app.launchEnvironment = ["UITESTS":"1"]
        
        app.launch()
        
        app.tabBars.buttons["Settings"].tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    

    func testGoProButtonNavigation() {
        
        app.buttons["go pro button"].tap()
        // make sure we get the button on the buy page
        let button = app.buttons["Buy button"]
        XCTAssertEqual(button.exists, true)
        
        app.navigationBars["Go Pro!"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testCreditsPageButtonNavigation() {
        
        let creditsButton = app.buttons["View the credits button"]
        creditsButton.tap()
        
        app.navigationBars["Credits"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testShowingSomeInformationAboutItems() {
        
        let tablesQuery = app.tables
        tablesQuery.children(matching: .cell).element(boundBy: 0).images["infoIcon"].tap()
        
        let okButton = app.alerts.buttons["Ok"]
        okButton.tap()
        tablesQuery.children(matching: .cell).element(boundBy: 1).images["infoIcon"].tap()
        okButton.tap()
        
    }
    
    func testPickingValuesAndThemSaving() {
        // for this guy we need to check the user defaults
        let selectcellCell = XCUIApplication().tables.children(matching: .cell).matching(identifier: "selectCell").element(boundBy: 0)
        
        let label = selectcellCell.staticTexts["currentValPicker"]
        
        label.tap()
        
        selectcellCell.swipeUp()
        
        label.tap()
        
        // make sure it saved in the user defaults
//        let newValue = UserDefaults.standard.object(forKey: PossibleSetting.sport.rawValue)
        
//        XCTAssertEqual(newValue, Sport.getSport())
//        print(newValue)
        
    }
    
    
    
}
