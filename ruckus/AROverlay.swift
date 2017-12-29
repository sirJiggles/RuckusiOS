//
//  AROverlay.swift
//  ruckus
//
//  Created by Gareth on 29.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import SpriteKit


class AROverlay: SKScene {
    weak var parentView: ARVC?
    
    // UI components (that need to be modified)
    var timeLabel = SKLabelNode(text: "00:00")
    var modeLabel = SKLabelNode(text: "working")
    var roundLabel = SKLabelNode(text: "Round: 0")
    
    convenience init(parent: ARVC, size: CGSize) {
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
        timeLabel.fontColor = UIColor.orange
        timeLabel.fontSize = fontSize
        timeLabel.fontName = fontName
        self.addChild(timeLabel)
        
        modeLabel.position = CGPoint(x: leftAlign, y: topAlign)
        modeLabel.fontColor = UIColor.orange
        modeLabel.fontSize = fontSize
        modeLabel.fontName = fontName
        self.addChild(modeLabel)
        
        // add rounds top right
        roundLabel.position = CGPoint(x: rightAlign, y: bottomAlign)
        roundLabel.color = UIColor.white
        roundLabel.fontSize = fontSize
        roundLabel.fontName = fontName
        self.addChild(roundLabel)
        
        
//        let playTexture = SKTexture(image: #imageLiteral(resourceName: "Play"))
//        playButtonNode = SKSpriteNode(texture: playTexture)
//        playButtonNode.size = CGSize(width: 100, height: 100)
//        playButtonNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        playButtonNode.position = CGPoint(x: self.size.width / 2.0, y: self.size.height / 2 - 200)
//        playButtonNode.name = buttonNames.playButton.rawValue
//
//        self.addChild(playButtonNode)
//
//        let titleTexture = SKTexture(image: #imageLiteral(resourceName: "Title"))
//        titleGame = SKSpriteNode(texture: titleTexture)
//        titleGame.size = CGSize(width: 300, height: 300)
//        titleGame.position = CGPoint(x: self.size.width / 2.0, y: self.size.height / 2 + 180)
//
//        self.addChild(titleGame)
//
//        scoreLabel.text = "0"
//        scoreLabel.fontColor = UIColor.white
//        scoreLabel.position = CGPoint(x: self.size.width / 2.0, y: self.size.height - 72)
        
    }
    
    // when the users tap on the overlay
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let pv = parentView {
//            pv.touchesFunction(touches, with: event)
//        }
    }
    
    // MARK: - Interval timer delegates
    
    
}

