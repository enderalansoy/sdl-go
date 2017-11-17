//
//  ProxyManager.swift
//  sdl-go
//
//  Created by Alan Endersoy on 21/07/2017.
//  Copyright © 2017 Alan Endersoy. All rights reserved.
//

import UIKit
import SmartDeviceLink

struct AppInfo {
    static let appName = "Easy Route App"
    static let appId = "312558813"
    static let ipAddress = ""
    static let port : UInt16 = 12345
    
}

enum SDLHMIFirstState {
    case none
    case nonNone
    case full
}

class ProxyManager: NSObject {
    var delegate: ConsoleLogDelegate?
    var sdlManager: SDLManager?
    var firstTimeState: SDLHMIFirstState = .none
    let ciContext = CIContext()
    
    //    var imageBuffer : CVPixelBuffer?
    //    var delegate : ConsoleLogDelegate?
    //    // Manager decleration
    //    var sdlManager: SDLManager?
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        
        super.init()
        
        // Used for USB Connection
        //        let lifecycleConfiguration = SDLLifecycleConfiguration
        //            .defaultConfiguration(withAppName: appName,
        //                                  appId: appId)
        
        /* Used for TCP/IP Connection
         let lifecycleConfiguration = SDLLifecycleConfiguration
         .debugConfiguration(withAppName: appName,
         appId: appId,
         ipAddress: "<#IP Address#>",
         port: <#Port#>)
         */
        
        //        // App icon image
        //        if let appImage = UIImage(named: "AppIcon") {
        //            let appIcon = SDLArtwork
        //                .persistentArtwork(with: appImage,
        //                                   name: "AppIcon",
        //                                   as: .JPG /* or .PNG */)
        //            lifecycleConfiguration.appIcon = appIcon
        //        }
        //
        //        // Short name for app (optional)
        //        lifecycleConfiguration.shortAppName = "EasyRoute"
        //
        //        // App type: .navigation
        //        lifecycleConfiguration.appType = .navigation()
        //
        //        // OEM Security Manager addition
        //        lifecycleConfiguration.securityManagers = [FMCSecurityManager.self]
        //
        //        // Lock screen enable/disable
        //        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration,
        //                                             lockScreen: .disabled())
        //
        //        sdlManager = SDLManager(configuration: configuration,
        //                                delegate: nil)
        //        super.init()
        //        sdlManager.delegate = self
    }
    
    func connect() {
        
        //        // Start watching for a connection with a SDL Core
        //
        //        sdlManager.start { (success, error) in
        //            if success {
        //                self.log("Hey")
        //                self.log("Connected")
        //            }
        //        }
        
        self.log("tryingToConnect1")
        
        delay(2) {
            
            self.sdlManager = SDLManager(configuration: ProxyManager.connectIAP(), delegate: self)
            self.sdlManager?.streamManager?.touchManager.touchEventDelegate = self
            
        }
        
        
        
        self.log("tryingToConnect2")
        
        delay(2) {
            
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
        lifecycleConfig.shortAppName = "EasyRoute"
        let appImage = UIImage(named: "test_image")
        lifecycleConfig.appIcon = SDLArtwork(image: appImage!, name: "AppIcon", persistent: true, as: .JPG)
        //lifecycleConfig.appIcon = SDLArtwork(image: UIImage(named:"test_image")!, name: AppInfo.logoName, persistent: true, as: .JPG)
        lifecycleConfig.appType = .navigation
        let streamingMediaConfig = SDLStreamingMediaConfiguration()
        streamingMediaConfig.securityManagers = [FMCSecurityManager.self]
        return SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: .enabled(), logging: .debug(), streamingMedia: streamingMediaConfig)
    }
}

extension ProxyManager: SDLManagerDelegate, SDLTouchManagerDelegate {
    
    
    func managerDidDisconnect() {
        self.firstTimeState = .none
        self.sdlManager = nil
    }
    
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        if newLevel != .none && firstTimeState == .none {
            // First time in a full, limited, or background state
            self.firstTimeState = .nonNone
        }
        
        if (newLevel == .full && firstTimeState != .full) {
            // First time in a full state
            self.firstTimeState = .full
            
            // Start streaming video
            let timer = Timer(timeInterval: 1.0/30.0, target: self, selector: #selector(sendCIImage), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .commonModes)
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
}

extension ProxyManager {
    
    
    func sendCIImage() -> Bool {
        let image: UIImage = UIImage(named: "test_image")!
        let ciImage = CIImage(image: image)
        
        let pixelbuffer = pixelBuffer(imageSize: image.size)
        guard pixelbuffer != nil else {
            return false
        }
        
        guard ciImage != nil else {
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
        let success = sdlManager?.streamManager?.sendVideoData(buffer)
        self.log("video was sent: \(success != nil && success == true ? "successfully" : "unsuccessfully")")
        self.log(success! ? "successful" : "unsuccessful")
        return success != nil ? success! : false
    }
}


//    func stopVideoSession() {
//        guard let streamManager = self.sdlManager.streamManager, streamManager.videoSessionConnected else {
//            return
//        }
//        streamManager.stopVideoSession()
//    }
//
//    func startVideoSession() {
//
//        guard let streamManager = self.sdlManager.streamManager,
//                  streamManager.videoSessionConnected,
//                  UIApplication.shared.applicationState != .active else {
//                    self.log(self.sdlManager.streamManager?.videoSessionConnected)
//                    self.log("returned")
//            return
//        }
//
//        self.log("streamManager")
//
//        streamManager.startVideoSession(withTLS: .authenticateAndEncrypt) { (success, encryption, error) in
//            if !success {
//                if let error = error {
//                    self.log("Error starting video session. \(error.localizedDescription)")
//                }
//                self.log("!success && !error")
//            } else {
//                self.log("success: start video session")
//                let imageBuffer = ImageProcessor.pixelBufferFromImage(image: UIImage(named: "test_image")!)
//                guard let streamManager = self.sdlManager.streamManager, streamManager.videoSessionConnected else {
//                    return
//                }
//                if encryption {
//                    if streamManager.sendVideoData(imageBuffer) == false {
//                        self.log("Could not send Video Data")
//                    }
//                    self.log("encryption && sendVideoData")
//
//                } else {
//                    if streamManager.sendVideoData(imageBuffer) == false {
//                        self.log("Could not send Video Data")
//                    }
//                    self.log("!encryption && sendVideoData")
//                }
//            }
//        }
//    }
//}
//
////MARK: SDLManagerDelegate
//extension ProxyManager: SDLManagerDelegate {
//    func managerDidDisconnect() {
//        self.log("Manager disconnected!")
//        log("Manager disconnected!")
//
//    }
//    // HMI Level control
//    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeTo newLevel: SDLHMILevel) {
//        if newLevel.isEqual(to: SDLHMILevel.limited()) || newLevel.isEqual(to: SDLHMILevel.full()) {
//            self.log("HMI:")
//            startVideoSession()
//        } else {
//            stopVideoSession()
//        }
//    }
//}

extension ProxyManager {
    func log(_ text: String) {
        self.delegate?.log(text)
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}

