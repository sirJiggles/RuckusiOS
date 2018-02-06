//
//  NotchUtils.swift
//  ruckus
//
//  Created by Gareth on 06.02.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import UIKit

class NotchUtils {
    func hasSafeAreaInsets() -> Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
        return UIApplication.shared.delegate?.window??.safeAreaInsets != .zero
        }
        return false
    }
}
