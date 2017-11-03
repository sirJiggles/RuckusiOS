//
//  PlistHelper.swift
//  ruckus
//
//  Created by Gareth on 12/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

enum PlistError: Error {
    case FileNotFound
    case ConversionError
    case FileCopyError
}

protocol PlistReadAndWritable {
    func setUpPlistForWriting() throws -> [String: AnyObject]
    func getPlist() throws -> [String: AnyObject]
    func updateValue(_ value: String, forKey key: String) -> ()
}

class PlistHelper: PlistReadAndWritable {
    var resource: String
    var plist: NSMutableDictionary
    var plistDocPath: String = ""
    
    init(resource: String) {
        self.resource = resource
        self.plist = [:]
    }
    
    // just get a plist and read it
    func getPlist() throws -> [String: AnyObject] {
        guard let path = Bundle.main.path(forResource: self.resource, ofType: "plist") else {
            throw PlistError.FileNotFound
        }
        guard let dict = NSDictionary(contentsOfFile: path), let castDict = dict as? [String:AnyObject] else {
            throw PlistError.ConversionError
        }
        return castDict
    }
    
    func setUpPlistForWriting() throws -> [String: AnyObject] {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        let path = documentDirectory.appending("\(self.resource).plist")
        
        // save the path for later reading
        self.plistDocPath = path
        
        let fileManager = FileManager.default
        
        // if we did not copy it over yet
        if(!fileManager.fileExists(atPath: path)){
            guard let bundlePath = Bundle.main.path(forResource: self.resource, ofType: "plist") else {
                throw PlistError.FileNotFound
            }
  
            // try to copy the bundle
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: path)
            } catch {
                throw PlistError.FileCopyError
            }

        }
        
        guard let dict = NSDictionary(contentsOfFile: path), let castDict = dict as? [String:AnyObject] else {
            throw PlistError.ConversionError
        }
        
        self.plist = NSMutableDictionary(contentsOfFile: path)!
        
        return castDict
    }
    
    
    func updateValue(_ value: String, forKey key: String) {
        self.plist.setValue(value, forKeyPath: "\(key).value")
        self.plist.write(toFile: self.plistDocPath, atomically: true)
    }
    
}
