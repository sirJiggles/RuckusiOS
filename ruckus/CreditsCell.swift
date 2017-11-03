//
//  CreditsCell.swift
//  ruckus
//
//  Created by Gareth on 04.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class CreditsCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var creditImage: UIImageView!
    
    var url: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func didClickView(_ sender: Any) {
        if let theUrl = URL(string: url) {
            UIApplication.shared.open(theUrl, completionHandler: nil)
        }
    }
}
