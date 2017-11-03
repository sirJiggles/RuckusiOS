//
//  FoldingViewCell.swift
//  ruckus
//
//  Created by Gareth on 16.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import WebKit
import FoldingCell

class HelpCell: FoldingCell {
    
    
    @IBOutlet weak var moveName: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var webview: WKWebView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func animationDuration(_ itemIndex:NSInteger, type:AnimationType)-> TimeInterval {
        
        // durations count equal it itemCount
        let durations = [0.26, 0.2, 0.2] // timing animation for each view
        return durations[itemIndex]
    }

}
