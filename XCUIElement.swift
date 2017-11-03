//
//  XCUIElement.swift
//  ruckus
//
//  Created by Gareth on 18.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import XCTest

extension XCUIElement {
    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}
