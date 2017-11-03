//
//  PurchasedState.swift
//  ruckus
//
//  Created by Gareth on 04.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

class PurchasedState {
    static var sharedInstance = PurchasedState()
    var isPaid: Bool = false
}
