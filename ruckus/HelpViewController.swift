//
//  HelpViewController.swift
//  ruckus
//
//  Created by Gareth on 16.08.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import FoldingCell

fileprivate struct C {
    struct CellHeight {
        static let close: CGFloat = 70 // equal or greater foregroundView height
        static let open: CGFloat = 380 // equal or greater containerView height
    }
}

fileprivate struct HelpData {
    var id: String = ""
    var descr: String = ""
    var label: String = ""
}

class HelpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var cellHeights = (0..<16).map { _ in C.CellHeight.close }
    
    let kCloseCellHeight: CGFloat = 70
    let kOpenCellHeight: CGFloat = 380
    let kRowsCount = 16
    
    // set up the data for the videos
    fileprivate let tableData: [HelpData] = [
        HelpData(
            id: "pwj1nrsXqWk",
            descr: "As seen in the video, wait for the combos to be called out and try to keep up! You can adjust the difficulty and type of hits in the settings screen",
            label: "How to use"
        ),
        HelpData(
            id: "iQo3bUw9o4U",
            descr: "A Jab is a lead hand punch. If you are in left stance your jab is a punch with your left hand. A jab can be a strike to the head or body.",
            label: "Jab"
        ),
        HelpData(
            id: "P2ZWYT0epTc",
            descr: "Cross is a rear hand punch. As an example if you are in left stance your cross will be a right hand punch. A cross, when called can be performed to the head or body.",
            label: "Cross"
        ),
        HelpData(
            id: "nRkMlBSAvyE",
            descr: "Hook is a punch that comes from the sides. Can be left or right and applied to the body or head.",
            label: "Hook"
        ),
        HelpData(
            id: "QLrQ9-gR9Us",
            descr: "A round kick is a kick that comes from around. It can be performed by the front or rear leg and can be a low or high kick. The trick with a round kick is all in the hips!.",
            label: "Round Kick"
        ),
        HelpData(
            id: "KjgbTi67jM8",
            descr: "A push kick or sometimes called a 'teep' kick is performed by bringing the leg directly up in front of you and pushing your opponent away from you. Can be the lead or rear leg.",
            label: "Push kick"
        ),
        HelpData(
            id: "j2HMD61XGuo",
            descr: "Side kicks can be performed by turning your body side on to your objective lifting the lead (front) leg horizontally, bending it bringing the knee towards your chest and pushing out.",
            label: "Side kick"
        ),
        HelpData(
            id: "WdDpujM0_cY",
            descr: "Elbows can be rear or lead, usually always to the head and you strike with the bottom section of the elbow.",
            label: "Elbow"
        ),
        HelpData(
            id: "jx6GWLOe4z8",
            descr: "A shin kick is a strike with the skin on the leg. Can be either rear or lead.",
            label: "Shin Kick"
        ),
        HelpData(
            id: "UW4sz8Kja4I",
            descr: "Spinning back fists are when you turn your body full circle (the spin). Then, as you come out of the spin you release the arm and strike the bag with the back of the hand.",
            label: "Spinning Back Fist"
        ),
        HelpData(
            id: "5ufo9oShaRg",
            descr: "When doing the jumping front kick lift the leg you do NOT want to strike with first. Once this is in the air spring of the leg that is on the floor while bringing the previously raised leg down. While the leg is coming up extend it and push towards the target focusing on moving your hips forwards as you strike. Try to keep your guard up.",
            label: "Jumping front kick"
        ),
        HelpData(
            id: "E23L2FatVEQ",
            descr: "Spring up first, directly up then once in the air focus on twisting the hips to bring the power over. Another tip is to, try to move towards to bag diagonally as you strike bringing with you the force of your body weight. Try to strike with the top side of the foot. Try to keep your guard up.",
            label: "Jumping round kick"
        ),
        HelpData(
            id: "xLNefBykzDo",
            descr: "Jump towards your target with your leg you intend to strike with extended. You can also jump directly up and extend the leg if there is no room or your opponent is attacking. Try to keep your guard up.",
            label: "Jumping side kick"
        ),
        HelpData(
            id: "scn6-W2lzns",
            descr: "This is not technically included but you can do it when a spinning side kick is called if you like. Jump directly up, twist for the spin but look over your shoulder before striking. You need to be able to see what you are hitting. This is a hard habit to get used to but worth it. And try to maintain the guard.",
            label: "Jumping spinning side kick"
        ),
        HelpData(
            id: "uKVJM8ouCwc",
            descr: "Try to flick your body to give you faster momentum on this move. Personally I tend to bend over a bit but some people prefer a more upright stance for this. Twist, look over the shoulder and extend the leg for the hook kick after seeing the target. Try to strike with the heel and maintain a good guard. Which is hard for this one.",
            label: "Spinning hook kick"
        ),
        HelpData(
            id: "_UaB0mcCqyA",
            descr: "As with the jumping version of this kick. Keep up the guard. Jump up then twist. Look over the shoulder, spot your target then strike and try to keep the hands up. This move is underestimated in power and range. Try to get close to the bag until it is uncomfortable.",
            label: "Spinning side kick"
        )
    ]

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case let cell as FoldingCell = tableView.cellForRow(at: indexPath) else {
            return
        }

        var duration = 0.0
        if cellHeights[indexPath.row] == kCloseCellHeight { // open cell
            cellHeights[indexPath.row] = kOpenCellHeight
            cell.selectedAnimation(true, animated: true, completion: nil)
            duration = 0.5
        } else {// close cell
            cellHeights[indexPath.row] = kCloseCellHeight
            cell.selectedAnimation(false, animated: true, completion: nil)
            duration = 1.1
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { _ in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if case let cell as FoldingCell = cell {
            if cellHeights[indexPath.row] == C.CellHeight.close {
                cell.selectedAnimation(false, animated: false, completion:nil)
            } else {
                cell.selectedAnimation(true, animated: false, completion: nil)
            }
        }
    }
    
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 16
    }
    
    // here we put the data in
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let data = tableData[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath) as? HelpCell {
            
            if let webView = cell.webview {
                let ytEmbed = "<style type='text/css'>body{padding:0;margin:0;background-color:#1C1C1D;width:100%;height:100%;}</style><html><body><iframe width='\(webView.frame.width)' height='212' src='https://www.youtube.com/embed/\(data.id)' frameborder='0' allowfullscreen></iframe></body></html>"
                
                webView.loadHTMLString(ytEmbed, baseURL: nil)
            }
            if let moveName = cell.moveName {
                moveName.text = data.label
            }
            if let details = cell.details {
                details.text = data.descr
            }
            return cell
        } else {
            // just return a cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath) as! HelpCell
            
            return cell
        }
        
//        return cell
        
    }

}
