//
//  WatchNotificationBridge.swift
//  ruckus
//
//  Created by Gareth on 01/04/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import WatchConnectivity

protocol WatchNotificationBridgeDelegate: class {
    func didSettupSession() -> Void
}

class WatchNotificationBridge: NSObject, WCSessionDelegate {
    
    var messageSession: WCSession?
    var sessionActive = false
    weak var delegate: WatchNotificationBridgeDelegate?
    
    static let sharedInstance = WatchNotificationBridge()
    
    func setUpSession() {
        if WCSession.isSupported() {
            // start a communication session
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sessionReachable() -> Bool {
        if let session = messageSession {
            if session.isReachable {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    // MARK: - Watch session delegates
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        messageSession = session
        sessionActive = true
        self.delegate?.didSettupSession()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        sessionActive = false
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        sessionActive = false
    }

    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let notification = NotificationKey(rawValue: message.keys.first!)!
        let payload = message.values.first! as! [String:Any]
        
        // send the notification out to all listeners
        NotificationCenter.default.post(name: Notification.Name(notification.rawValue), object: nil, userInfo: payload)

        // always respond with a timestamp
        replyHandler(["responseTime": NSDate()])
    }
    
    // MARK: - Sending messages
    func sendMessage(_ message: NotificationKey, callback: ((NSDate) -> Void)?) {
        if let session = messageSession {
            if session.isReachable {
                session.sendMessage([message.rawValue: ["":""]], replyHandler: { (respones) -> Void in
                    if let cb = callback, let timestamp = respones["responseTime"] as? NSDate  {
                        cb(timestamp)
                    }
                }, errorHandler: { (error) in
                    // @TODO handle error
                })
            }
        }
    }
    
    func sendMessageWithPayload(_ message: NotificationKey, payload: [String:Any], callback: (() -> Void)?) {
        if let session = messageSession {
            if session.isReachable {
                session.sendMessage([message.rawValue: payload], replyHandler: { (response) in
                    // just fire the CB
                    if let cb = callback {
                        cb()
                    }
                }, errorHandler: { (error) in
                    // @TODO handle error here
                })
            }
        }
    }
}
