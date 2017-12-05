//
//  AppLink.swift
//  sdl-go
//
//  Created by Yanki Insel on 28/11/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import UIKit
import MapKit

class AppLink: XibViewHelper {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var centerLabel: UILabel!
    
    override func awakeFromNib() {
        centerLabel.text = String(describing: mapView.center)
    }
    
}
