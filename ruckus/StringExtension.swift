//
//  StringExtension.swift
//  ruckus
//
//  Created by Gareth on 20/03/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

extension String {
    func stringTimeToDouble() -> Double {
        let parts = self.components(separatedBy: ":")
        let minsInSeconds = Int(parts[0])! * 60
        let seconds = Int(parts[1])!
        return Double(minsInSeconds + seconds)
    }
    var camelcaseString: String {
        let source = self
        let first = source.lowercased().substring(to: source.index(after: source.startIndex))
        if source.characters.contains(" ") {
            let cammel = source.capitalized.replacingOccurrences(of: " ", with: "")
            let rest = String(cammel.characters.dropFirst())
            return "\(first)\(rest)"
        } else {
            let rest = String(source.characters.dropFirst())
            return "\(first)\(rest)"
        }
    }
}
