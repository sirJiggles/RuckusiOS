//
//  ARTourVC.swift
//  ruckus
//
//  Created by Gareth on 25.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import UIKit

protocol TourPageDelegate: class {
    func didTapCta(with action: String) -> Void
}

class ARTourVC: UIViewController, TourPageDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    let tourData = [
        [
            "image": "tour1",
            "title": "Don't try to punch",
            "cta": false
        ],
        [
            "image": "tour2",
            "title": "Dodge the punches",
            "cta": false
        ],
        [
            "image": "tour3",
            "title": "Secure your phone",
            "cta": true,
            "ctaAction": "ARBoxing"
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        settupPageViews()
    }
    
    func createPageView(data: [String: AnyObject]) -> TourPage {
        let pageView = TourPage.loadFromNib()
        pageView.configure(data: data)
        return pageView;
    }
    
    func settupPageViews() {
        var totalWidth: CGFloat = 0
        
        for data in tourData {
            let pageView = createPageView(data: data as [String : AnyObject])
            pageView.frame = CGRect(origin: CGPoint(x: totalWidth, y:0), size: view.bounds.size)
            
            scrollView.addSubview(pageView)
            
            totalWidth += pageView.bounds.size.width
            
            pageView.delegate = self
        }
        
        scrollView.contentSize = CGSize(width: totalWidth, height: scrollView.bounds.height)
        
    }
    
    // if we tapped one of the CTA's on the view
    func didTapCta(with action: String) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: action) {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    
}

extension ARTourVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // how wide is the page
        let pageWidth = Int(scrollView.contentSize.width) / tourData.count
        
        pageControl.currentPage = Int(scrollView.contentOffset.x) / pageWidth
    }
    
}

