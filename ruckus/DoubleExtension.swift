//
//  DoubleExtension.swift
//  ruckus
//
//  Created by Gareth on 11/03/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

extension Double {
    func splitAtDecimal() -> [Int?] {
        return ("\(self)".characters.split{ $0 == "." }).map({
            let s = String($0)
            if s.characters.count > 2 {
                let index = s.index(s.startIndex, offsetBy: 2)
                let sub = s.substring(to: index)
                return Int(sub)
            } else {
                return Int(s)
            }
        })
    }
}
