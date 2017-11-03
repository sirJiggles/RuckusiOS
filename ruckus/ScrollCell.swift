//
//  ScrollCell.swift
//  ruckus
//
//  Created by Gareth on 22/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class ScrollCell: UITableViewCell {

    @IBOutlet weak var slider: UISlider!
    
    weak var callDelegate: ChangeScrollDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    @IBAction func valueChanged(_ sender: Any) {
        self.callDelegate?.didChangeScrollValue(sender: self, newValue: slider.value)
    }
    
    @IBAction func endTouch(_ sender: Any) {
        self.callDelegate?.didReleaseScroll()
    }
    

}
