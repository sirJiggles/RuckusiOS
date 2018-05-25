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
    @IBOutlet weak var pageDescr: UILabel!
    @IBOutlet weak var ctaHeight: NSLayoutConstraint!
    @IBOutlet weak var titleTop: NSLayoutConstraint!
    
    weak var delegate: TourPageDelegate?
    
    class func loadFromNib() -> TourPage {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "TourPage", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! TourPage
        
        return view
        
    }
    
    func configure(data: [String:AnyObject]) {
        if NotchUtils().hasSafeAreaInsets() {
            ctaHeight.constant = 90
        }
        if let title = data["title"] as? String, let image = data["image"] as? String, let ctaVisible = data["cta"] as? Bool, let descr = data["descr"] as? String {
            pageLabel.text = title
            pageImage.image = UIImage(named: image)
            cta.isHidden = !ctaVisible
            pageDescr.text = descr
        }
    }
    // IBActions
    @IBAction func tapCTA(_ sender: Any) {
        delegate?.didTapCta()
    }
}

