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
import GLKit

class AppLinkViewController: UIViewController, ViewDelegate {

    @IBOutlet weak var appLinkView: AppLink!
    @IBOutlet weak var pointLabel: UILabel!
    var map: MKMapView!
    var count = 0
    let panQueue = DispatchQueue(label: "com.easyroute.panQueue", qos: .utility)
    let pinchQueue = DispatchQueue(label: "com.easyroute.pinchQueue", qos: .utility)

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
    
    func captureScreen() -> CGImage? {
        
        return appLinkView.snapshot()

    }
    
    func handlePan(translation: Translation) {
        
        /** set center method */
//        self.count += 1
//        self.appLinkView.centerLabel.text = String(describing:self.count)
//        let coeff: CGFloat = 5
//        let newCenter = CGPoint(x: self.map.center.x - coeff*translation.x, y: self.map.center.y - coeff*translation.y)
//        let center = map.convert(newCenter, toCoordinateFrom: map)
//        queue.async {
//
//            self.map.setCenter(self.map.convert(newCenter, toCoordinateFrom: self.map), animated: true)
//        }
        
        /**set region method */
        let span = self.map.region.span
        let coeff: CGFloat = 8
        let newCenter = CGPoint(x: self.map.center.x - coeff*translation.x, y: self.map.center.y - coeff*translation.y)
        
            let center = self.map.convert(newCenter, toCoordinateFrom: self.map)
            let region = MKCoordinateRegion(center: center, span: span)
        DispatchQueue.main.async {
            self.map.setRegion(region, animated: true)
        }
    }
    
    func zoomMap(on point: CGPoint, with scale: CGFloat) {
        let span = map.region.span
        let center = map.convert(point, toCoordinateFrom: map)
        let newSpan = MKCoordinateSpanMake(span.latitudeDelta * CLLocationDegrees(scale), span.longitudeDelta * CLLocationDegrees(scale))
        let region = MKCoordinateRegion(center: center, span: newSpan)
        pinchQueue.async {
            self.map.setRegion(region, animated: true)
        }
    }
}
