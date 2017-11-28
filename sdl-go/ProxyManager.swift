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

struct AppInfo {
    static let appName = "Easy Route App"//"SyncProxyTester"//"Easy Route App"
    static let appId = "312558813"//"883259982"//"312558813"
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
    var timer = Timer(timeInterval: 1.0/30.0, target: self, selector: #selector(sendCIImage), userInfo: nil, repeats: true)
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
    }
    
    func connect() {
        self.sdlManager = SDLManager(configuration: ProxyManager.connectIAP(), delegate: self)
        self.sdlManager?.streamManager?.touchManager.touchEventDelegate = self
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
        lifecycleConfig.shortAppName = "EasyRoute"//"SyncProxyTester"
        let appImage = UIImage(named: "test_image2")
        lifecycleConfig.appIcon = SDLArtwork(image: appImage!, name: "AppIcon2", persistent: true, as: .JPG)
        //lifecycleConfig.appIcon = SDLArtwork(image: UIImage(named:"test_image")!, name: AppInfo.logoName, persistent: true, as: .JPG)
        lifecycleConfig.appType = .navigation
        let streamingMediaConfig = SDLStreamingMediaConfiguration(securityManagers: [FMCSecurityManager.self])
        return SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: .enabled(), logging: .debug(), streamingMedia: streamingMediaConfig)
    }
}

extension ProxyManager: SDLManagerDelegate, SDLTouchManagerDelegate {
    
    func managerDidDisconnect() {
        self.firstTimeState = .none
        self.sdlManager = nil
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        
//        if newLevel != .none && oldLevel == .none {
//            //None -> Non-none
//            startVideoStreaming()
//
//        } else if newLevel == .none && oldLevel != .none {
//            //Non-none -> None
//            stopVideoStreaming()
//        }

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
        RunLoop.main.add(timer, forMode: .commonModes)
        
    }
    
    func stopVideoStreaming() {
        timer.invalidate()
    }
}

extension ProxyManager {
    
    func sendCIImage() -> Bool {
        
        guard let image = captureScreen() else {
            self.log("Cant capture screen")
            return false
        }
        
        let ciImage = CIImage(image: image)
        let pixelbuffer = pixelBuffer(imageSize: image.size)
        
        guard pixelbuffer != nil else {
            self.log("no pixelbuffer")
            return false
        }
        
        guard ciImage != nil else {
            self.log("no ciImage")
            return false
        }
        
        ciContext.render(ciImage!, to: pixelbuffer!, bounds: (ciImage?.extent)!, colorSpace: CGColorSpaceCreateDeviceRGB())
        let success = sendVideo(pixelbuffer!)
        return success
    }
    
    func pixelBuffer(imageSize: CGSize) -> CVPixelBuffer? {
        
        var pixelBuffer: CVPixelBuffer? = nil
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(imageSize.width), Int(imageSize.height), kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        
        if status != kCVReturnSuccess {
            self.log("something went wrong when creating pixel buffer: \(status)")
        }
        
        return pixelBuffer
    }

    func sendVideo(_ buffer: CVPixelBuffer) -> Bool {
        
        guard let streamManager = sdlManager?.streamManager else {
            self.log("no Stream Manager")
            return false
        }
        
        let success = streamManager.sendVideoData(buffer)
        self.log("video was sent: \(success ? "successfully" : "unsuccessfully")")
        return success
    }
}

extension ProxyManager {
    
    func log(_ text: String) {
        self.delegate?.log(text)
    }
    
    func captureScreen() -> UIImage? {
        return self.delegate?.captureScreen()
    }
}

