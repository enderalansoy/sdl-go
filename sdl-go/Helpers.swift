import UIKit
import VideoToolbox
import CoreVideo

// casts UIView into UIImage
extension UIImage {
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}

extension UIView {
    
    func snapshot() -> CGImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0 )
        UIGraphicsGetCurrentContext()?.interpolationQuality = .none
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return (image!.cgImage)!
    }
    
//    func snapshot() -> CGImage {
//
//        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
//        let image = renderer.image { ctx in
//            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
//        }
//        return image.cgImage!
//    }
    
    
}

struct Translation {
    var x: CGFloat
    var y: CGFloat
}


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
        context?.interpolationQuality = .none
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
        
    }
    
}
