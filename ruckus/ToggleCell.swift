//
//  ToggleCell.swift
//  ruckus
//
//  Created by Gareth on 12/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class ToggleCell: UITableViewCell {
    
    
    @IBOutlet weak var toggleSwitch: UISwitch!
    weak var callDelegate: ToggleCellDelegate?
    weak var toggleInfoDelegete: ClickInfoIconDelegate?

    @IBOutlet weak var infoImage: UIImageView!
    
    override func awakeFromNib() {
        infoImage.tintColor = UIColor.blackSeven
        
        // add the tap gesture for the info icon
        infoImage.isUserInteractionEnabled = true
        infoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedImage)))
        
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func tappedImage() {
        self.toggleInfoDelegete?.didClickInfo(sender: self)
    }
    
    @IBAction func toggleSwitchToggle(_ sender: Any) {
        self.callDelegate?.didToggle(sender: self, isOn: toggleSwitch.isOn)
    }
    
}
