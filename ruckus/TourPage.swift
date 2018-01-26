//
//  PageViewConytoller.swift
//  Tour
//
//  Created by Gareth on 11/09/16.
//  Copyright © 2016 Gareth. All rights reserved.
//

import Foundation
import UIKit

class TourPage: UIView {
    
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var cta: UIButton!
    
    var clickAction: String = ""
    weak var delegate: TourPageDelegate?
    
    class func loadFromNib() -> TourPage {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "TourPage", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! TourPage
        
        return view
        
    }
    
    func configure(data: [String:AnyObject]) {
        if let title = data["title"] as? String, let image = data["image"] as? String, let ctaVisible = data["cta"] as? Bool {
            pageLabel.text = title
            pageImage.image = UIImage(named: image)
            cta.isHidden = !ctaVisible
            
            // if the cta is visible and has an action set the
            // string we use for the click action here for the page
            // navigation
            if ctaVisible {
                if let action = data["ctaAction"] as? String {
                    clickAction = action
                }
            }
        }
    }
    // IBActions
    @IBAction func tapCTA(_ sender: Any) {
        if clickAction != "" {
            delegate?.didTapCta(with: clickAction)
        }
    }
}

