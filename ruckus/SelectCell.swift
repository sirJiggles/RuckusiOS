//
//  SelectCell.swift
//  ruckus
//
//  Created by Gareth on 16/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class SelectCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate, SelectableCell {
    
    @IBOutlet weak var selectedValue: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var infoImage: UIImageView!
    
    weak var callDelegate: SelectClickDelegate?
    weak var toggleInfoDelegete: ClickInfoIconDelegate?
    
    var values:[String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setSource()
        
        // set up image tint
        arrowImage.tintColor = UIColor.blackSeven
        
        // set color of selected label
        selectedValue.textColor = UIColor.textWhite
        
        // hide the picker to start with
        picker.isHidden = true
        picker.alpha = 0.0
        
        // set up the info image
        infoImage.tintColor = UIColor.blackSeven
        
        // add the tap gesture for the info icon
        infoImage.isUserInteractionEnabled = true
        infoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedImage)))
        
    }
    
    @objc func tappedImage() {
        self.toggleInfoDelegete?.didClickInfo(sender: self)
    }
    
    func setSource() {
        picker.dataSource = self
        picker.delegate = self
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let myTitle = NSAttributedString(string: values[row], attributes: [NSForegroundColorAttributeName: UIColor.white])
        return myTitle
    }
    
    
    // MARK: - Picker view delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if values.indices.contains(row) {
            selectedValue.text = values[row]
            self.callDelegate?.didClickSelectLabel(sender: self, newValue: values[row])
        }
    }
    
    // MARK: Selectable cell delegate
    
    // Animate the showing and hiding of the picker for this instance of the cell
    func openPickerView() {
        picker.isHidden = false
        // spin the arrow image
        UIView.animate(withDuration: 0.2) { 
            self.arrowImage.transform = self.arrowImage.transform.rotated(by: CGFloat.pi / 2.0)
        }
        UIView.animate(withDuration: 0.7, animations: {
            self.picker.alpha = 1.0
        })
    }
    
    func closePickerView(_ tableView: UITableView) {
        tableView.beginUpdates()
        picker.isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.picker.alpha = 0
            self.arrowImage.transform = CGAffineTransform.identity
        }, completion: { (value: Bool) in
            self.picker.isHidden = true
            tableView.endUpdates()
        })
    }
    
    func resetVisibility() {
        picker.isHidden = true
        picker.alpha = 0.0
        self.arrowImage.transform = CGAffineTransform.identity
    }
}
