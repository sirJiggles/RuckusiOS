//
//  AROverlay.swift
//  ruckus
//
//  Created by Gareth on 29.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import SpriteKit


class VROverlay: SKScene {
    weak var parentView: VRVC?
    
    // UI components (that need to be modified)
    var timeLabel = SKLabelNode(text: "00:00")
    var modeLabel = SKLabelNode(text: "Working")
    var roundLabel = SKLabelNode(text: "Round: 1")
    var punchLabel = SKLabelNode(text: "Hits: 0")
    
    convenience init(parent: VRVC, size: CGSize) {
        self.init(sceneSize: size)
        
        parentView = parent
    }
    
    convenience init(sceneSize: CGSize) {
        self.init(size: sceneSize)
        
        let paddingLR = CGFloat(self.size.width / 5)
        let paddingTB = CGFloat(self.size.height / 5)
        let topAlign = self.size.height - paddingTB
        let leftAlign = paddingLR
        let rightAlign = self.size.width - paddingLR
        let bottomAlign = paddingTB
        let fontSize = CGFloat(17.0)
        let fontName = "Impact"
        
        // add the time and the mode
        timeLabel.position = CGPoint(x: rightAlign, y: topAlign)
        timeLabel.fontColor = UIColor.theOrange
        timeLabel.fontSize = fontSize
        timeLabel.fontName = fontName
        self.addChild(timeLabel)
        
        modeLabel.position = CGPoint(x: leftAlign, y: topAlign)
        modeLabel.fontColor = UIColor.theOrange
        modeLabel.fontSize = fontSize
        modeLabel.fontName = fontName
        self.addChild(modeLabel)
        
        // add rounds top right
        roundLabel.position = CGPoint(x: rightAlign, y: bottomAlign)
        roundLabel.color = UIColor.white
        roundLabel.fontSize = fontSize
        roundLabel.fontName = fontName
        self.addChild(roundLabel)
        
        // add punch label bottom left
        punchLabel.position = CGPoint(x: leftAlign, y: bottomAlign)
        punchLabel.color = UIColor.white
        punchLabel.fontSize = fontSize
        punchLabel.fontName = fontName
        self.addChild(punchLabel)
    }
    
}

