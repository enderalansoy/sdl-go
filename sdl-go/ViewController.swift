//
//  ViewController.swift
//  sdl-go
//
//  Created by mac13 on 21/07/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import UIKit

protocol ConsoleLogDelegate {
    func log(_ text: String)
}

class ViewController: UIViewController, ConsoleLogDelegate {
	
    @IBOutlet weak var label: UILabel!
    
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
        label.text = "\(self.label.text)\n\(text)"
    }
}
