//
//  VolumeCell.swift
//  ruckus
//
//  Created by Gareth on 22.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class VolumeCell: UITableViewCell {
    var settingsAccessor: SettingsAccessor?
    

    override func awakeFromNib() {
        settingsAccessor = SettingsAccessor()
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func tapPlay(_ sender: Any) {
        // get and set volume first
        if let volumeSetting = settingsAccessor?.getVolume() {
            SoundPlayer.sharedInstance.setNewVolume(volumeSetting)
        }
        
        // just run a combo when pressed to get an idea of the volume setting
        HitCaller.sharedInstance.runCombo()
    }
    

}
