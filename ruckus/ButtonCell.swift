//
//  ButtonCell.swift
//  ruckus
//
//  Created by Gareth on 04.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    
    weak var callDelegate: ButtonCallDelegate?
    @IBOutlet weak var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // this one for now is just going to go to the credits screen
    @IBAction func didTapButton(_ sender: Any) {
        callDelegate?.didPressButton(sender: self)
    }
}
