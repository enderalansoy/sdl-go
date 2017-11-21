//
//  ImageProcessor.swift
//  sdl-go
//
//  Created by mac13 on 22/07/2017.
//  Copyright © 2017 mac13. All rights reserved.
//

import CoreVideo
import UIKit

struct ImageProcessor {
	static func pixelBuffer (forImage image:CGImage) -> CVPixelBuffer? {
		
		let frameSize = CGSize(width: image.width, height: image.height)
		
		var pixelBuffer:CVPixelBuffer? = nil
		let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
		
		if status != kCVReturnSuccess {
			return nil
		}
		
		CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
		let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
		let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
		let context = CGContext(data: data, width: Int(frameSize.width), height: Int(frameSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
		
		context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
		
		return pixelBuffer
	}    
    
}

// UIView -> UIImage
// .e.g: UIImage(view: myView)
extension UIImage {
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}

