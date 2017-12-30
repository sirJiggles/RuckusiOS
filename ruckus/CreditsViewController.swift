//
//  CreditsViewController.swift
//  ruckus
//
//  Created by Gareth on 04.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit

class CreditsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableData: [[String: Any]]
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Lifecycle
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        // a horid static list for the credits, but whateva treva
        tableData = [
            [
                "label": "DinosoftLabs",
                "image": #imageLiteral(resourceName: "fire-small"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/DinosoftLabs"
            ],
            [
                "label": "Chanut is Industries",
                "image": #imageLiteral(resourceName: "stopApp"),
                "tint": false,
                "url": "http://www.flaticon.com/authors/freepik"
            ],
            [
                "label": "Chanut is Industries",
                "image": #imageLiteral(resourceName: "pauseApp"),
                "tint": false,
                "url": "http://www.flaticon.com/authors/chanut-is-industries"
            ],
            [
                "label": "Chanut is Industries",
                "image": #imageLiteral(resourceName: "padlock"),
                "tint": false,
                "url": "http://www.flaticon.com/authors/chanut-is-industries"
            ],
            [
                "label": "Chanut is Industries",
                "image": #imageLiteral(resourceName: "padlock-unlocked"),
                "tint": false,
                "url": "http://www.flaticon.com/authors/chanut-is-industries"
            ],
            [
                "label": "Freepik",
                "image": #imageLiteral(resourceName: "playApp"),
                "tint": false,
                "url": "http://www.flaticon.com/authors/freepik"
            ],
            [
                "label": "Madebyoliver",
                "image": #imageLiteral(resourceName: "boxing"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/Madebyoliver"
            ],
            [
                "label": "Chris Veigt",
                "image": #imageLiteral(resourceName: "info"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/chris-veigt"
            ],
            [
                "label": "Freepik",
                "image": #imageLiteral(resourceName: "sad"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/freepik"
            ],
            [
                "label": "Freepik",
                "image": #imageLiteral(resourceName: "angry"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/freepik"
            ],
            [
                "label": "Madebyoliver",
                "image": #imageLiteral(resourceName: "settings"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/Madebyoliver"
            ],
            [
                "label": "Dario Ferrando",
                "image": #imageLiteral(resourceName: "clock"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/Dario-Ferrando"
            ],
            [
                "label": "Freepik",
                "image": #imageLiteral(resourceName: "rate"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/freepik"
            ],
            [
                "label": "Gregor Cresnar",
                "image": #imageLiteral(resourceName: "arrow"),
                "tint": true,
                "url": "http://www.flaticon.com/authors/gregor-cresnar"
            ]
        ]
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.title = "Credits"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view shit
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    // here we put the data in
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
        let cell = tableView.dequeueReusableCell(withIdentifier: "creditsCell", for: indexPath) as! CreditsCell
        
        if let label = tableData[indexPath.row]["label"] as? String {
            cell.label.text = label
        }
        if let image = tableData[indexPath.row]["image"] as? UIImage {
            cell.creditImage.image = image
        }
        if let tint = tableData[indexPath.row]["tint"] as? Bool {
            if tint {
                cell.creditImage.tintColor = UIColor.white
            }
            
        }
        if let url = tableData[indexPath.row]["url"] as? String {
            cell.url = url
        }

        
        return cell
    
    }
    
    func reloadTableData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
}
