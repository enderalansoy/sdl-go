//
//  AppLinkViewController.swift
//  sdl-go
//
//  Created by Yanki Insel on 29/11/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class AppLinkViewController: UIViewController, ViewDelegate {

    @IBOutlet weak var appLinkView: AppLink!
    @IBOutlet weak var pointLabel: UILabel!
    var map: MKMapView!
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProxyManager.sharedManager.delegate = self
        if let map = self.appLinkView.mapView {
            self.map = map
            self.map.isUserInteractionEnabled = true
        }
    }
    
    func log(_ text: String) {
        pointLabel.text = text
        //print(text)
    }
    
    func captureScreen() -> UIImage? {
        let image = UIImage(view: appLinkView)
        return image
        
//        let imageFrame = UIImageView(frame: CGRect(x: 0, y: 0, width: 800, height: 400))
//        imageFrame.contentMode = .scaleAspectFit
//        imageFrame.image = image
//        imageFrame.clipsToBounds = true
//        return UIImage(view: imageFrame)
    }
    
    func mapPan(recognizer: UIPanGestureRecognizer) {
        recognizer.translation(in: self.appLinkView.mapView)
    }
    
    func handlePan(translation: Translation) {
    
        self.count += 1
        self.appLinkView.centerLabel.text = String(describing:self.count)
        let newCenter = CGPoint(x: self.map.center.x - translation.x, y: self.map.center.y - translation.y)
        self.map.setCenter(self.map.convert(newCenter, toCoordinateFrom: self.map), animated: true)
    }
}
