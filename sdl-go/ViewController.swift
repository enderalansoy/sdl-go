//
//  ViewController.swift
//  sdl-go
//
//  Created by mac13 on 21/07/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import UIKit

protocol ViewDelegate {
    func log(_ text: String)
    func captureScreen() -> UIImage?
}

class ViewController: UIViewController, ViewDelegate {
	
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UITextView!
    
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
        let prevText = label.text
        label.text = "\(prevText ?? "")\n\(text)"
    }
    
    func captureScreen() -> UIImage? {
        imageView.image = UIImage(view: scrollContentView)
        imageView.contentMode = .scaleToFill
        return UIImage(view:imageView)
    }
}
