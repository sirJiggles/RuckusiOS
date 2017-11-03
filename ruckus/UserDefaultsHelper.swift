//
//  UserDefaultsHelper.swift
//  ruckus
//
//  Created by Gareth on 15/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

protocol UserDefaultable {
    func getValue(forKey key: String) -> Any?
    func setValue(_ value: Any, forKey key: String) -> ()
}

class UserDefaultsHelper: UserDefaultable {
    var defaults: UserDefaults
    
    init() {
        self.defaults = UserDefaults()
    }
    
    func getValue(forKey key: String) -> Any? {
        return self.defaults.object(forKey: key)
    }
    
    func setValue(_ value: Any, forKey key: String) -> () {
        self.defaults.set(value, forKey: key)
    }
}
