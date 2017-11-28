//
//  ViewController.swift
//  sdl-go
//
//  Created by mac13 on 21/07/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import UIKit
import MapKit

protocol ViewDelegate {
    func log(_ text: String)
    func captureScreen() -> UIImage?
}

class ViewController: UIViewController, ViewDelegate {
	
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        ProxyManager.sharedManager.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    func log(_ text: String) {
//        let prevText = label.text
//        label.text = "\(prevText ?? "")\n\(text)"
        print(text)
    }
    
    func captureScreen() -> UIImage? {

        imageView.contentMode = .center

        let image = UIImage(view: mapView)
        imageView.image = image
        imageView.clipsToBounds = true
        //let image = UIImage(view:imageView)
//        guard let image = UIImage(named:"image_ford") else {
//            print("No image")
//            return .none
//        }
        //imageView.image = image

//        return image

//        let location = CLLocation(latitude: 40.975427, longitude: 29.231953)
//        takeSnapshot(location, self.imageView) { image, error in
//            if let image = image {
//                self.imageView.image = image
//            } else {
//                print("no image")
//            }
//
//        }
        return UIImage(view: imageView)
    }
    
    func takeSnapshot(_ location: CLLocation, _ imageView: UIImageView, _ withCallback: @escaping (UIImage?, Error?) -> ()) {
        let options = MKMapSnapshotOptions()
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        options.region = coordinateRegion
        options.size = imageView.frame.size
        options.scale = UIScreen.main.scale
        
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error)
                return
            }
            
            withCallback(snapshot!.image, nil)
        }
    }
}
