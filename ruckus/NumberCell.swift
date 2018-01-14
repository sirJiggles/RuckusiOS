//
//  NumberCell.swift
//  ruckus
//
//  Created by Gareth on 14.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import UIKit

class NumberCell: UITableViewCell {
    
    // outlets
    
    @IBOutlet weak var numberInput: UITextField!
    @IBOutlet weak var infoImage: UIImageView!
    
    weak var callDelegate: EnterNumberDelegate?
    weak var toggleInfoDelegete: ClickInfoIconDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // set up the info image
        infoImage.tintColor = UIColor.blackSeven
        
        // add the tap gesture for the info icon
        infoImage.isUserInteractionEnabled = true
        infoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedImage)))
        
        // set up text input, crazy you have to do this ...
        let numberToolbar: UIToolbar = UIToolbar()
        numberToolbar.barStyle = UIBarStyle.default
        numberToolbar.items=[
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(NumberCell.done))
        ]
        
        numberToolbar.sizeToFit()
        
        numberInput.inputAccessoryView = numberToolbar
    }
    
    @objc func done() {
        numberInput.resignFirstResponder()
    }
    
    @objc func tappedImage() {
        self.toggleInfoDelegete?.didClickInfo(sender: self)
    }


    @IBAction func didEnterNumber(_ sender: Any) {
        self.callDelegate?.didEnterNumber(sender: self, newValue: numberInput.text!)
    }
    
    
    
    
}
