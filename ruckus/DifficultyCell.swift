//
//  DifficultyCell.swift
//  ruckus
//
//  Created by Gareth on 20/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class DifficultyCell: UITableViewCell {

    
    @IBOutlet weak var difficultySlider: UISlider!
    
    @IBOutlet weak var sadImage: UIImageView!
    
    @IBOutlet weak var angryImage: UIImageView!
    
    weak var callDelegate: ChangeDifficultyDelegate?
    
    override func awakeFromNib() {
        self.adjustImageTints()
        
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func adjustImageTints() {
        sadImage.tintColor = UIColor.white.withAlphaComponent(CGFloat(1 - difficultySlider.value))
        angryImage.tintColor = UIColor.white.withAlphaComponent(CGFloat(difficultySlider.value))
    }
    
    @IBAction func changeDifficultyValue(_ sender: Any, forEvent event: UIEvent) {
        self.callDelegate?.didChangeDifficulty(sender: self, newValue: difficultySlider.value)
        adjustImageTints()
    }

    @IBAction func releaseTouch(_ sender: Any) {
        self.callDelegate?.didReleaseScroll()
    }
}
