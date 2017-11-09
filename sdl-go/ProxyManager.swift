//
//  ProxyManager.swift
//  sdl-go
//
//  Created by Alan Endersoy on 21/07/2017.
//  Copyright © 2017 Alan Endersoy. All rights reserved.
//

import UIKit
import SmartDeviceLink

class ProxyManager: NSObject {
	// Constants for App Name and App ID
	private let appName = "Easy Route App"
	private let appId = "312558813"
	
	// Manager decleration
	fileprivate let sdlManager: SDLManager
	
	// Singleton
	static let sharedManager = ProxyManager()
	
	private override init() {
		// Used for USB Connection
		let lifecycleConfiguration = SDLLifecycleConfiguration
			.defaultConfiguration(withAppName: appName,
			                      appId: appId)
		
		/* Used for TCP/IP Connection
		let lifecycleConfiguration = SDLLifecycleConfiguration
		.debugConfiguration(withAppName: appName,
		appId: appId,
		ipAddress: "<#IP Address#>",
		port: <#Port#>)
		*/
		
		// App icon image
		if let appImage = UIImage(named: "AppIcon") {
			let appIcon = SDLArtwork
				.persistentArtwork(with: appImage,
				                   name: "AppIcon",
				                   as: .JPG /* or .PNG */)
			lifecycleConfiguration.appIcon = appIcon
		}
		
		// Short name for app (optional)
		lifecycleConfiguration.shortAppName = "EasyRoute"
		
		// App type: .navigation
		lifecycleConfiguration.appType = .navigation()
		
		// OEM Security Manager addition
		lifecycleConfiguration.securityManagers = [FMCSecurityManager.self]
		
		// Lock screen enable/disable
		let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration,
		                                     lockScreen: .disabled())
		
		sdlManager = SDLManager(configuration: configuration,
		                        delegate: nil)
		super.init()
		sdlManager.delegate = self
	}
	
	func connect() {
		// Start watching for a connection with a SDL Core
		sdlManager.start { (success, error) in
			if success {
				print("Hey")
			}
		}
	}
	
	func stopVideoSession() {
		guard let streamManager = self.sdlManager.streamManager, streamManager.videoSessionConnected else {
			return
		}
		streamManager.stopVideoSession()
	}
	
	func startVideoSession() {
		guard let streamManager = self.sdlManager.streamManager,
			streamManager.videoSessionConnected,
			UIApplication.shared.applicationState != .active else {
				return
		}
		streamManager.startVideoSession(withTLS: .authenticateAndEncrypt) { (success, encryption, error) in
			if !success {
				if let error = error {
					NSLog("Error starting video session. \(error.localizedDescription)")
				}
			} else {
				let imageBuffer = ImageProcessor.pixelBuffer(forImage: (#imageLiteral(resourceName: "beach.jpg")).cgImage!)
				guard let streamManager = self.sdlManager.streamManager, streamManager.videoSessionConnected else {
					return
				}
				if encryption {
					if streamManager.sendVideoData(imageBuffer!) == false {
						print("Could not send Video Data")
					}
				} else {
					if streamManager.sendVideoData(imageBuffer!) == false {
						print("Could not send Video Data")
					}
				}
			}
		}
	}
}

//MARK: SDLManagerDelegate
extension ProxyManager: SDLManagerDelegate {
	func managerDidDisconnect() {
		print("Manager disconnected!")
	}
	// HMI Level control
	func hmiLevel(_ oldLevel: SDLHMILevel, didChangeTo newLevel: SDLHMILevel) {
		if newLevel.isEqual(to: SDLHMILevel.limited()) || newLevel.isEqual(to: SDLHMILevel.full()) {
			startVideoSession()
		} else {
			stopVideoSession()
		}
	}
}
