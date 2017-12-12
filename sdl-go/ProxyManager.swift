//
//  ProxyManager.swift
//  sdl-go
//
//  Created by Alan Endersoy on 21/07/2017.
//  Copyright © 2017 Alan Endersoy. All rights reserved.
//

import UIKit
import SmartDeviceLink
import CoreImage
import MapKit

protocol ViewDelegate {
    func log(_ text: String)
    func captureScreen() -> CGImage?
    func handlePan(translation: Translation)
    func zoomMap(on point: CGPoint, with scale: CGFloat)
}

struct AppInfo {
    static let appName = "SyncProxyTester"//"SyncProxyTester"//"Easy Route App"
    static let appId = "883259982"//"883259982"//"312558813"
    static let ipAddress = ""
    static let port : UInt16 = 12345
}

enum SDLHMIFirstState {
    case none
    case nonNone
    case full
}

class ProxyManager: NSObject {
    
    var delegate: ViewDelegate?
    var sdlManager: SDLManager?
    var firstTimeState: SDLHMIFirstState = .none
    let ciContext = CIContext()
    var pixelbuffer: CVPixelBuffer!
    
    var count = 0
    var dif: Translation!
    var zoomScale: CGFloat = 0
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
        resetDif()
    }
    
    func connect() {
        //appLinkView = AppLink(frame: CGRect(x: 0, y: 0, width: 800, height: 380))

        self.sdlManager = SDLManager(configuration: ProxyManager.connectIAP(), delegate: self)
        
        self.sdlManager?.streamManager?.touchManager.touchEventDelegate = self
        
        // To Register
        //NotificationCenter.default.addObserver(self, selector: #selector(touchEventAvailable(_:)), name: .SDLDidReceiveTouchEvent, object: nil)
        
        self.sdlManager!.start { (success, error) in
            if success {
                self.log("Successfully connected to a SDL enabled accessory")
            } else {
                self.log("Could not connect with a SDL enabled accessory")
                self.log(error as! String)
            }
        }
    }
}

private extension ProxyManager {
    
    class func connectIAP() -> SDLConfiguration {
        let lifecycleConfiguration =
            SDLLifecycleConfiguration(appName: AppInfo.appName, appId: AppInfo.appId)
        return setupConfiguration(with: lifecycleConfiguration)
    }
    
    class func connectTCP() -> SDLConfiguration {
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: AppInfo.appName, appId: AppInfo.appId, ipAddress: AppInfo.ipAddress, port: AppInfo.port)
        return setupConfiguration(with: lifecycleConfiguration)
    }
    
    class func setupConfiguration(with lifecycleConfig: SDLLifecycleConfiguration) -> SDLConfiguration  {
        lifecycleConfig.shortAppName = "SyncProxyTester"//"SyncProxyTester"
        let appImage = UIImage(named: "test_image2")
        lifecycleConfig.appIcon = SDLArtwork(image: appImage!, name: "AppIcon2", persistent: true, as: .JPG)
        //lifecycleConfig.appIcon = SDLArtwork(image: UIImage(named:"test_image")!, name: AppInfo.logoName, persistent: true, as: .JPG)
        lifecycleConfig.appType = .navigation
        let streamingMediaConfig = SDLStreamingMediaConfiguration(securityManagers: [FMCSecurityManager.self])
        return SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: .enabled(), logging: .debug(), streamingMedia: streamingMediaConfig)
    }
}

extension ProxyManager: SDLManagerDelegate {
    
    func managerDidDisconnect() {
        self.firstTimeState = .none
        //self.sdlManager = nil
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {

        if newLevel != .none && firstTimeState == .none {
            // First time in a full, limited, or background state
            self.firstTimeState = .nonNone
        }

        if (newLevel == .full && firstTimeState != .full) {
            // First time in a full state
            self.firstTimeState = .full
            startVideoStreaming()
        }

        if newLevel == .full {
            // Full state

        } else if newLevel == .limited {
            // Limited state

        } else if newLevel == .background {
            // Background state

        } else if newLevel == .none {
            // None state
        }
    }
    
    func startVideoStreaming() {
        
        let timer = Timer(timeInterval: 1.0/30.0, target: self, selector: #selector(sendBuffer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .commonModes)
        
    }
}

extension ProxyManager {
    
    func sendBuffer() -> Bool {
        guard let buffer = ImageProcessor.pixelBuffer(forImage: self.captureScreen()!) else { return false }
        return sendVideo(buffer)
    }

    func sendVideo(_ buffer: CVPixelBuffer) -> Bool {
        
        guard let streamManager = sdlManager?.streamManager else {
            self.log("no Stream Manager")
            return false
        }
        
        let success = streamManager.sendVideoData(buffer)
        //self.log("video was sent: \(success ? "successfully" : "unsuccessfully")")
        return success
    }
}

extension ProxyManager {
    
    func log(_ text: String) {
        self.delegate?.log(text)
    }
    
    func captureScreen() -> CGImage? {
        return self.delegate?.captureScreen()
    }
}

//MARK:: Touch Delegate Operations
extension ProxyManager: SDLTouchManagerDelegate {
    
    public func touchManager(_ manager: SDLTouchManager, didReceiveSingleTapFor view: UIView?, at point: CGPoint) {
        self.delegate?.log("Single Tap at \(point).")
    }
    
    public func touchManager(_ manager: SDLTouchManager, didReceiveDoubleTapFor view: UIView?, at point: CGPoint) {
        self.delegate?.log("Double Tap at \(point).")

    }

     public func touchManager(_ manager: SDLTouchManager, didReceivePanningFrom fromPoint: CGPoint, to toPoint: CGPoint) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.handlePan(fromPoint, toPoint)
        }
    }
    
     public func touchManager(_ manager: SDLTouchManager, didReceivePinchAtCenter point: CGPoint, withScale scale: CGFloat) {
        self.delegate?.log("Pinch at \(point) with scale \(scale).")
        DispatchQueue.global(qos: .userInteractive).async {
            self.handlePinch(point, scale)
        }

    }
    
    //Do Pinch if above limit
    public func handlePinch(_ point: CGPoint, _ scale: CGFloat) {
        zoomScale += scale-1
        if abs(zoomScale) > 0.3 {
            if zoomScale < 0 {
                zoomScale = 1-zoomScale
            }
            self.delegate?.zoomMap(on: point, with: zoomScale)
            zoomScale = 0
        }
    }
    
    
    //Do Pan if above the limit
    public func handlePan(_ from: CGPoint, _ to: CGPoint) {
        
        let translation = Translation(x: to.x-from.x, y: to.y-from.y)
        self.delegate?.handlePan(translation: translation)
        
        
//        DispatchQueue.main.async {
//            self.sumDif(translation)
//            if (abs(self.dif.x) > 50) || (abs(self.dif.y) > 50) {
//                self.delegate?.handlePan(translation: self.dif)
//                self.resetDif()
//            }
//        }

    }
    
    // Reset Pan limit
    func resetDif() {
        self.dif = Translation(x: 0, y: 0)
    }
    
    // Sum Pan coordinates
    func sumDif(_ with: Translation) {
        self.dif.x += with.x
        self.dif.y += with.y
    }

    
 /** Get touch events without using delegate methods **/
    
    // On Receive
    @objc fileprivate func touchEventAvailable(_ notification: SDLRPCNotificationNotification) {
        
        guard let touchEvent = notification.notification as? SDLOnTouchEvent else {
            print("Error retrieving onTouchEvent object")
            return
        }

        // Grab something like type
        let type = touchEvent.type
        if type == .end {
            resetDif()
            zoomScale = 0
        }
        //self.delegate?.log(type._rawValue as String)
    }

}
