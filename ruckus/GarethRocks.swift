//
//  SecondViewController.swift
//  ruckus
//
//  Created by Gareth on 01/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

protocol ToggleCellDelegate: class {
    func didToggle(sender: ToggleCell, isOn: Bool)
}

protocol SelectClickDelegate: class {
    func didClickSelectLabel(sender: SelectCell)
}

enum SettingsError: Error {
    case CouldNotLoadPlist
    case CouldNotGetSettingsKeyFromStore
}

class SettingsViewController: UITableViewController, ToggleCellDelegate, SelectClickDelegate {
    
    let tableData: [String: AnyObject]
    let settings: Settings
    let pickerData: [String]
    
//    @IBOutlet weak var tableView: UITableView!
    
    required init?(coder aDecoder: NSCoder) {
        settings = Settings(usingPlist: "Settings")
        
        do {
            // load the Plist as the "base" for how the settings are structured
            tableData = try settings.loadPlist()
        } catch let error {
            fatalError("\(error)")
            // @TODO should throw here
        }
        
        pickerData = []
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch section {
//        case 0:
//            return 4
//        case 1:
//            return 7
//        case 2:
//            return 1
//        case 3:
//            return 2
//        case 4:
//            return 1
//        default:
//            return 0
//        }
        return tableData.count
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print("selected row")
        let cellType = settings.typeOfCell(atIndex: indexPath.row)
        if (cellType == .selectCell) {
            print("selected a select cell")
            // get the cell handle
            let cell = tableView.dequeueReusableCell(withIdentifier: CellType.selectCell.rawValue, for: indexPath) as! SelectCell
            
            // get the picker from the cell (so we can animate it)
            let picker: UIPickerView = cell.contentView.viewWithTag(3) as! UIPickerView
            
            self.togglePicker(pickerView: picker)
        }
    }
    
    // if the user clicks a select type of cell we want to toggle the cell
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("gareth")
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = settings.typeOfCell(atIndex: indexPath.row)
        let cell = configureCell(withType: cellType, atIndex: indexPath)
        return cell!
    }
    
    func configureCell(withType type: CellType, atIndex index: IndexPath) -> UITableViewCell? {
        let cellKey = settings.keyForCell(atIndex: index.row)
        
        let storedValue: String
        
        do {
            storedValue = try settings.getValue(forKey: cellKey.rawValue)!
            
        } catch let error {
            fatalError("\(error)")
            // @TODO should throw here
//            throw SettingsError.CouldNotGetSettingsKeyFromStore
        }
        
        guard let data = tableData[cellKey.rawValue], let label = data["label"] else {
            print("Could not get the data")
            return nil
        }
        
        switch type {
        case .toggleCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! ToggleCell
            let cellLabel: UILabel = cell.contentView.viewWithTag(1) as! UILabel
            cellLabel.text = label as? String
            
            let toggleState: Bool = storedValue == "1"
            let toggleCell: UISwitch = cell.contentView.viewWithTag(2) as! UISwitch
            toggleCell.isOn = toggleState
            
            cell.callDelegate = self
            return cell
        case .selectCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! SelectCell
            let cellLabel: UILabel = cell.contentView.viewWithTag(1) as! UILabel
            cellLabel.text = label as? String
            
            // set the current stored value for the select
            let selectedLabel: UILabel = cell.contentView.viewWithTag(2) as! UILabel
            selectedLabel.text = storedValue
    
            
            return cell
        }
        
       
    }
    
    //MARK: - Delegates for types of cell events
    func didToggle(sender: ToggleCell, isOn: Bool) {
        let indexPath = self.tableView.indexPath(for: sender)
        let newValue = isOn ? "1" : "0"
        settings.setValue(newValue, forIndex:indexPath!.row)
    }
    
    func didClickSelectLabel(sender: SelectCell) {
        // now populate the select with the data for the index and show the picker
//        let indexPath = self.tableView.indexPath(for: sender)
        
    }
    
    // MARK: - Animations
    func togglePicker(pickerView: UIPickerView) {
        if pickerView.isHidden {
            pickerView.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                pickerView.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                pickerView.alpha = 0.0
            }, completion: { (value: Bool) in
                pickerView.isHidden = true
            })
        }
    }


    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

