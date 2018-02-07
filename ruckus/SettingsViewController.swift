//
//  SettingsViewController.swift
//  ruckus
//
//  Created by Gareth on 16/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import CoreGraphics
//import StoreKit

protocol SelectableCell {
    func openPickerView()
    func closePickerView(_ tableView: UITableView)
    func resetVisibility()
}

protocol ButtonCallDelegate: class {
    func didPressButton(sender: ButtonCell)
}

protocol ClickInfoIconDelegate: class  {
    func didClickInfo(sender: UITableViewCell)
}

protocol ToggleCellDelegate: class {
    func didToggle(sender: ToggleCell, isOn: Bool)
}

protocol SelectClickDelegate: class {
    func didClickSelectLabel(sender: SelectCell, newValue: String)
}

protocol SelectTimeClickDelegate: class {
    func didClickSelectTimeLabel(sender: SelectCellTime, newValue: String)
}

protocol ChangeDifficultyDelegate: class {
    func didChangeDifficulty(sender: DifficultyCell, newValue: Float)
    
    func didReleaseScroll()
}

protocol ChangeScrollDelegate: class {
    func didChangeScrollValue(sender: ScrollCell, newValue: Float)
    
    func didReleaseScroll()
}

protocol EnterNumberDelegate: class {
    func didEnterNumber(sender: NumberCell, newValue: String)
}

enum SettingsError: Error {
    case CouldNotLoadPlist
    case CouldNotGetSettingsKeyFromStore
}

class SettingsViewController: UIViewController, ChangeScrollDelegate, ChangeDifficultyDelegate, ToggleCellDelegate, SelectClickDelegate, UITableViewDataSource, UITableViewDelegate, ClickInfoIconDelegate, ButtonCallDelegate, SelectTimeClickDelegate, EnterNumberDelegate {

    let tableData: [String: AnyObject]
    let settings: Settings
    // for deciding wich picker is open
    var selectStates: [String:Bool]
    
    var canReachWatch = false
    
    var notificationBridge: WatchNotificationBridge
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var rateButtonPaid: UIButton!
    @IBOutlet weak var rateAndUpgrade: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        settings = Settings(usingPlist: "Settings")
        
        do {
            // load the Plist as the "base" for how the settings are structured
            tableData = try settings.loadPlist()
        } catch let error {
            fatalError("\(error)")
            // @TODO should throw here
        }
        
        selectStates = [:]
        
        notificationBridge = WatchNotificationBridge.sharedInstance
        

        super.init(coder: aDecoder)
    }
    
    // MARK: lifecycle
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if PurchasedState.sharedInstance.isPaid || currentReachabilityStatus == .notReachable {
            rateButtonPaid.isHidden = false
            rateAndUpgrade.isHidden = true
        } else {
            rateButtonPaid.isHidden = true
            rateAndUpgrade.isHidden = false
        }
        
        self.navigationController?.isNavigationBarHidden = true
        
        canReachWatch = notificationBridge.sessionReachable()
        
        reloadTableData()
    }
    
    override func viewDidLoad() {
        // set up the rate us button
        rateButton.layer.cornerRadius = 2
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadTableData),
            name: NSNotification.Name(NotificationKey.SettingsSync.rawValue),
            object: nil
        )
        
        self.edgesForExtendedLayout = UIRectEdge.all;
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, (self.tabBarController?.tabBar.frame)!.height, 0.0);
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // update the settings on the watch
        if (notificationBridge.sessionReachable()) {
            let settings = UserDefaults.standard.dictionaryRepresentation()
            notificationBridge.sendMessageWithPayload(.UserDefaultsPayloadFromApp, payload: settings, callback: nil)
        }
    }
    
    // MARK: - Notification functions and reseting table data
    @objc func reloadTableData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func clickRate(_ sender: Any) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(AppStoreIdents.pro.rawValue)&action=write-review") {
            UIApplication.shared.open(url, completionHandler: nil)
        }
    }
    
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 6
        case 1:
            return 8
        case 2:
            return 1
        case 3:
            return 2
        case 4:
            return 1
        case 5:
            return 2
        case 6:
            return 1
        default:
            return 1
        }
    }
    
    // close up and reset the select cells that are not on the screen
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        if cellType == .selectCell || cellType == .selectCellTime {
            if let cell = tableView.cellForRow(at: indexPath) as? SelectableCell {
                let key = selectStateKey(forPath: indexPath)
                selectStates[key]! = false;
                cell.resetVisibility()
            }
        }
        
    }
    
    // close select cells when deselected
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        if cellType == .selectCell || cellType == .selectCellTime {
            if let cell = tableView.cellForRow(at: indexPath) as? SelectableCell {
                let key = selectStateKey(forPath: indexPath)
                selectStates[key]! = false;
                cell.closePickerView(tableView)
            }
        }
    }
    
    // if the user clicks a select type of cell we want to toggle the cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        
        if cellType == .selectCell || cellType == .selectCellTime {
            if let cell = tableView.cellForRow(at: indexPath) as? SelectableCell {
                let key = selectStateKey(forPath: indexPath)
                
                if selectStates[key]! {
                    cell.closePickerView(tableView)
                    selectStates[key]! = false
                } else {
                    tableView.beginUpdates()
                    selectStates[key]! = true
                    tableView.endUpdates()
                    cell.openPickerView()
                }
            }
        } else {
            closeSelectCells()
        }
        
    }
    
    // set all as closed
    func closeSelectCells() {
        for (key,open) in selectStates {
            // if open
            if open {
                var parts = key.split{$0 == ":"}.map(String.init)
                
                parts[0].remove(at: parts[0].startIndex)
                parts[1].remove(at: parts[1].startIndex)
                
                guard let row = Int(parts[0]), let section = Int(parts[1]) else {
                    return
                }
                
                let indexPath = IndexPath(row: row, section: section)
                if let cell = tableView.cellForRow(at: indexPath) as? SelectableCell {
                    selectStates[key] = false
                    cell.closePickerView(tableView)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Timer settings"
        case 1:
            return "Features"
        case 2:
            return "Difficulty"
        case 3:
            return "Volume"
        case 4:
            return "Your Height (in cm)"
        case 5:
            return "AR Settings"
        case 6:
            return "Credits"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
        header.backgroundView?.backgroundColor = UIColor.blackOne
    }
    
    // make sure if we will re-render a select cell it gets the right values assigned to it
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        if cellType == .selectCell || cellType == .selectCellTime {
            var storedValue: String
            let cellKey = settings.keyForCell(atIndexPath: indexPath)
            
            do {
                storedValue = try settings.getValue(forKey: cellKey.rawValue)! as! String
            } catch let error {
                fatalError("\(error)")
            }
            
            if cellType == .selectCell {
                if let cell = cell as? SelectCell {
                    
                    guard let data = tableData[cellKey.rawValue], let values = data["possibleValues"] as? [String] else {
                        fatalError("Could not get the data for the picker")
                    }
                    
                    cell.values = values
                    
                    if let selectedIndex = values.index(of: storedValue as String) {
                        cell.picker!.selectRow(selectedIndex, inComponent: 0, animated: false)
                    }
                    
                    // THIS STUPID LINE COST ME HOURS
                    cell.setSource()
                }
                
            } else if cellType == .selectCellTime {
                
                if let cell = cell as? SelectCellTime {
                    
                    
                    let parts = storedValue.components(separatedBy: ":")
                    guard let mins = Int(parts[0]), let seconds = Int(parts[1]) else {
                        return
                    }
                    
                    if let minsPicker = cell.minsPicker, let secondsPicker = cell.secondsPicker {
                        minsPicker.selectRow(mins, inComponent: 0, animated: false)
                        let secondsValue = (seconds == 0) ? 0 : seconds / 5
                        secondsPicker.selectRow(secondsValue, inComponent: 0, animated: false)
                    }
                    
                    cell.setSource()
                }
            }
            
        } else if (cellType == .toggleCell) {
            // set the enabled / disabled
            if let cell =  cell as? ToggleCell {
                let cellKey = settings.keyForCell(atIndexPath: indexPath)
                do {
                    let enabled = try settings.getEnabled(forKey: cellKey.rawValue)!
                    cell.toggleSwitch.isEnabled = enabled as Bool
                } catch let error {
                    fatalError("\(error)")
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        let cell = configureCell(withType: cellType, atIndex: indexPath)
        return cell!
    }
     
    func configureCell(withType type: CellType, atIndex index: IndexPath) -> UITableViewCell? {
        let cellKey = settings.keyForCell(atIndexPath: index)
        
        let storedValue: Any
        
        // bail out of the volume cell fast
        if type == .volumeCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! VolumeCell
            return cell
        }
        
        
        do {
            storedValue = try settings.getValue(forKey: cellKey.rawValue)!
        } catch let error {
            fatalError("\(error)")
        }
        
        guard let data = tableData[cellKey.rawValue], let label = data["label"] else {
            fatalError("Could not get the data")
        }
        
        switch type {
        case .toggleCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! ToggleCell
            let cellLabel: UILabel = cell.contentView.viewWithTag(1) as! UILabel
            cellLabel.text = label as? String
            cellLabel.textColor = UIColor.textWhite
            
            let toggleState: Bool = storedValue as? String == "1"
            
            cell.toggleSwitch.isOn = toggleState
            
            cell.callDelegate = self
            cell.toggleInfoDelegete = self
            return cell
        case .selectCell:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! SelectCell
            
            let cellLabel: UILabel = cell.contentView.viewWithTag(1) as! UILabel
            cellLabel.text = label as? String
            cellLabel.textColor = UIColor.textWhite
            
            // set the current stored value for the select
            cell.selectedValue!.text = storedValue as? String
            
            cell.callDelegate = self
            cell.toggleInfoDelegete = self
            
            let key = selectStateKey(forPath: index)
            selectStates[key] = false;
            
            return cell
        case .selectCellTime:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! SelectCellTime
            
            let cellLabel: UILabel = cell.contentView.viewWithTag(1) as! UILabel
            cellLabel.text = label as? String
            cellLabel.textColor = UIColor.textWhite
            
            // set the current stored value for the select
            if let currentValue = storedValue as? String {
                cell.selectedValue!.text = currentValue
                
                let parts = currentValue.components(separatedBy: ":")
                cell.currentMins = parts[0]
                cell.currentSeconds = parts[1]
                
            }
            
            cell.callDelegate = self
            cell.toggleInfoDelegete = self
            
            let key = selectStateKey(forPath: index)
            selectStates[key] = false;
            
            return cell
        
        case .numberCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! NumberCell
            
            // set the initial value
            cell.numberInput.text = storedValue as? String
            
            // set delegates
            cell.callDelegate = self
            cell.toggleInfoDelegete = self
            
            return cell
            
        case .difficultyCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! DifficultyCell
            
            cell.callDelegate = self
            
            cell.difficultySlider.value = storedValue as! Float
            
            return cell
        case .scrollCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! ScrollCell
            
            cell.callDelegate = self
            
            cell.slider.value = storedValue as! Float
            
            return cell
        case .buttonCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! ButtonCell
            cell.button.setTitle("View Credits", for: .normal)
            cell.callDelegate = self
            return cell
        case .volumeCell:
            // we should never get here ...
            let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: index) as! VolumeCell
            return cell
        }
        
        
    }
    
    // set the height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellType = settings.typeOfCell(atIndexPath: indexPath)
        
        if cellType == .volumeCell {
            return 90.0
        }
        
        if cellType == .selectCell || cellType == .selectCellTime {
            if let open = self.selectStates["r\(indexPath.row):s\(indexPath.section)"] {
                if open {
                    return 280.0
                }
                return 57.0
            }
            return 57.0
        }
        return 57.0
    }
    
    //MARK: - Delegates for types of cell events
    func didToggle(sender: ToggleCell, isOn: Bool) {
        let indexPath = self.tableView.indexPath(for: sender)
        let newValue = isOn ? "1" : "0"
        let cellKey = settings.keyForCell(atIndexPath: indexPath!)
        settings.setValue(newValue, atIndexPath: indexPath!)
        
        // if the newValue is off. check if there are any other toggles this toggle
        // disables
        disableRetaledToggles(forKey: cellKey, currentState: isOn);
        
        // check if we need to close any selected cells that might have been open
        self.closeSelectCells()
    }
    
    func didEnterNumber(sender: NumberCell, newValue: String) {
        let indexPath = self.tableView.indexPath(for: sender)
        settings.setValue(newValue, atIndexPath: indexPath!)
    }
    
    // right now it is just one, that is credits button
    func didPressButton(sender: ButtonCell) {
        performSegue(withIdentifier: "showCreditsView", sender: nil)
    }
    
    func didClickSelectLabel(sender: SelectCell, newValue: String) {
        // now populate the select with the data for the index and show the picker
        let indexPath = self.tableView.indexPath(for: sender)
        settings.setValue(newValue, atIndexPath: indexPath!)
    }
    
    func didClickSelectTimeLabel(sender: SelectCellTime, newValue: String) {
        let indexPath = self.tableView.indexPath(for: sender)
        settings.setValue(newValue, atIndexPath: indexPath!)
    }
    
    func didChangeDifficulty(sender: DifficultyCell, newValue: Float) {
        let indexPath = self.tableView.indexPath(for: sender)
        settings.setValue(newValue, atIndexPath: indexPath!)
    }
    
    func didChangeScrollValue(sender: ScrollCell, newValue: Float) {
        let indexPath = self.tableView.indexPath(for: sender)
        settings.setValue(newValue, atIndexPath: indexPath!)
    }
    
    func didReleaseScroll() {
        closeSelectCells()
    }
    
    
    // when the user clicks info, show an alert with the information
    func didClickInfo(sender: UITableViewCell) {
        let indexPath = self.tableView.indexPath(for: sender)
        let cellKey = settings.keyForCell(atIndexPath: indexPath!)
        if let descr = tableData[cellKey.rawValue]?["descr"] {
            if let descrString = descr as? String {
                self.showAlert(descrString)
            }
        }
    }
    
    // MARK: - Util functions for cells
    func selectStateKey(forPath indexPath: IndexPath) -> String {
        return "r\(indexPath.row):s\(indexPath.section)"
    }
    
    func showAlert(_ descr: String) {
        let alert = UIAlertController(title: nil, message: descr, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func disableRetaledToggles(forKey cellKey: PossibleSetting, currentState isOn: Bool) {
        if let data = tableData[cellKey.rawValue], let disables = data["disables"] as? [String] {
            
            var subDisables: [PossibleSetting] = []
            
            for toggleName in disables {
                // get cell instance for toggle and disbale / enable it
                guard let setting = PossibleSetting(rawValue: toggleName) else {
                    // @TODO this is a recoverable error
                    print("Could not convert to setting")
                    return
                }
                if let subData = tableData[setting.rawValue], let subDataDisables = subData["disables"] as? [String] {
                    if subDataDisables.count > 0 {
                        subDisables.append(setting)
                    }
                }
                let indexPath = settings.indexPathForToggle(forSetting: setting)
                if let cell = tableView.cellForRow(at: indexPath) as? ToggleCell {
                    cell.toggleSwitch.isEnabled = isOn
                }
                // save the setting (even if not on the screen right now)
                settings.setEnabled(isOn, atIndexPath: indexPath)
            }
            
            for subDisable in subDisables {
                let indexPath = settings.indexPathForToggle(forSetting: subDisable)
                if let cell = tableView.cellForRow(at: indexPath) as? ToggleCell {
                    if (!cell.toggleSwitch.isOn) {
                        self.disableRetaledToggles(forKey: subDisable, currentState: cell.toggleSwitch.isOn)
                    }
                }
            }
            
        }
    }
}
