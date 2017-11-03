//
//  AppNotificationBridge.swift
//  ruckus
//
//  Created by Gareth on 01/04/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import WatchConnectivity

protocol AppNotificationBridgeProtocol: class {
    func didSetUpSession() -> Void
    func couldNotSettupSession() -> Void
}

class AppNotificationBridge: NSObject, WCSessionDelegate {
    var messageSession: WCSession?
    weak var delegate: AppNotificationBridgeProtocol?
    
    // is singleton
    static let sharedInstance = AppNotificationBridge()
    
    func setUpSession() {
        // check if the session is supported
        if WCSession.isSupported() {
            // start a communication session
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        } else {
           self.delegate?.couldNotSettupSession()
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
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        
    }
    
    
    // MARK: - Watch session delegates
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            self.delegate?.couldNotSettupSession()
        } else {
            messageSession = session
            self.delegate?.didSetUpSession()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let notification = NotificationKey(rawValue: message.keys.first!)!
        let payload = message.values.first! as! [String:Any]
        
        // send the notification out to all listeners
        NotificationCenter.default.post(name: Notification.Name(notification.rawValue), object: nil, userInfo: payload)
        
        // always respond with a timestamp
        replyHandler(["responseTime": NSDate()])
        
    }
    
    // MARK: communication messages
    func sendMessage(_ message: NotificationKey, callback: ((NSDate) -> Void)?) {
        if let session = messageSession {
            if session.isReachable {
                session.sendMessage([message.rawValue : ["":""]], replyHandler: { (respones) -> Void in
                    if let cb = callback, let timestamp = respones["responseTime"] as? NSDate  {
                        cb(timestamp)
                    }
                }, errorHandler: { (error) in
                    // @TODO handle errors when cant connect to app
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
