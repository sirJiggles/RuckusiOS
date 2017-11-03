//
//  SelectCellTime.swift
//  ruckus
//
//  Created by Gareth on 16/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class SelectCellTime: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate, SelectableCell {
    
    @IBOutlet weak var selectedValue: UILabel!
    @IBOutlet weak var minsPicker: UIPickerView!
    @IBOutlet weak var secondsPicker: UIPickerView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var infoImage: UIImageView!
    
    weak var callDelegate: SelectTimeClickDelegate?
    weak var toggleInfoDelegete: ClickInfoIconDelegate?
    
    let minValues = [Int](0...20)
    var secondsValues: [Int] = []
    var currentMins = ""
    var currentSeconds = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setSource()
        
        // set up image tint
        arrowImage.tintColor = UIColor.blackSeven
        
        // set color of selected label
        selectedValue.textColor = UIColor.textWhite
        
        // hide the picker to start with
        minsPicker.isHidden = true
        minsPicker.alpha = 0.0
        secondsPicker.isHidden = true
        secondsPicker.alpha = 0.0
        
        secondsValues.append(contentsOf: stride(from: 0, to: 60, by: 5))
        
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
        secondsPicker.dataSource = self
        secondsPicker.delegate = self
        minsPicker.dataSource = self
        minsPicker.delegate = self
    }
    
    func getStringNumber(_ value: Int) -> String {
        if value < 10 {
            return "0\(value)"
        }
        return String(value)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if pickerView == minsPicker {
            return NSAttributedString(string: String(minValues.index(row, offsetBy: 0)), attributes: [NSForegroundColorAttributeName: UIColor.white])
        }
        return NSAttributedString(string: getStringNumber(secondsValues.index(row, offsetBy: 0) * 5), attributes: [NSForegroundColorAttributeName: UIColor.white])
    }
    
    
    // MARK: - Picker view delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == minsPicker {
            return String(minValues.index(row, offsetBy: 0))
        }
        return getStringNumber(secondsValues.index(row, offsetBy: 0) * 5)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == minsPicker {
            return minValues.count
        }
        return secondsValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == minsPicker {
            if minValues.indices.contains(row) {
                currentMins = String(minValues.index(row, offsetBy: 0))
                
            }
        } else {
            if secondsValues.indices.contains(row) {
                currentSeconds = getStringNumber(secondsValues.index(row, offsetBy: 0) * 5)
            }
        }
        
        let newValue = "\(currentMins):\(currentSeconds)"
        selectedValue.text = newValue
        
        self.callDelegate?.didClickSelectTimeLabel(sender: self, newValue: newValue)
        
    }
    
    // Animate the showing and hiding of the picker for this instance of the cell
    func openPickerView() {
        minsPicker.isHidden = false
        secondsPicker.isHidden = false
        // spin the arrow image
        UIView.animate(withDuration: 0.2) {
            self.arrowImage.transform = self.arrowImage.transform.rotated(by: CGFloat.pi / 2.0)
        }
        UIView.animate(withDuration: 0.7, animations: {
            self.minsPicker.alpha = 1.0
            self.secondsPicker.alpha = 1.0
        })
    }
    
    func closePickerView(_ tableView: UITableView) {
        tableView.beginUpdates()
        minsPicker.isHidden = false
        secondsPicker.isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.minsPicker.alpha = 0
            self.secondsPicker.alpha = 0
            self.arrowImage.transform = CGAffineTransform.identity
        }, completion: { (value: Bool) in
            self.minsPicker.isHidden = true
            self.secondsPicker.isHidden = true
            tableView.endUpdates()
        })
    }
    
    func resetVisibility() {
        minsPicker.isHidden = true
        minsPicker.alpha = 0.0
        secondsPicker.isHidden = true
        secondsPicker.alpha = 0.0
        self.arrowImage.transform = CGAffineTransform.identity
    }
}
