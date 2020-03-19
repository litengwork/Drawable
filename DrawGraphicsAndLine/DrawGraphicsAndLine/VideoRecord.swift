//
//  VideoRecord.swift
//  DrawGraphicsAndLine
//
//  Created by ri on 2019/07/23.
//  Copyright © 2019 Lee. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation


protocol VideoRecorderDelegate: class {
    func videoRecordingComplete()
}



class VideoRecord: NSObject {
    
    public weak var delegate: VideoRecorderDelegate? = nil
    public var filePath: String! = ""
    public var frameRate: Int = 30
    
    public var recording: Bool = false
    private var writing: Bool = false
    private var isPause: Bool = false
    private var spaceDate: Float = 0
    private var videoWriter: AVAssetWriter? = nil
    private var videoWriterInput: AVAssetWriterInput? = nil
    private var avAdaptor: AVAssetWriterInputPixelBufferAdaptor? = nil
    private var startedAt: Date? = nil
    private var timer: Timer? = nil
    fileprivate let videoBitrate: UInt32 = 9000000    /// bps
    fileprivate let mediaTimeScale: CMTimeScale = 2400  /// fps
    fileprivate var displayLink: CADisplayLink? = nil
    
    override init() {
        
        recording = false
        isPause = false
        writing = false
        spaceDate = 0
    }
    
    deinit {
        
        cleanupWriter()
    }
    
    // MARK: - public
    
    
    /// ビデオレコード開始
    ///
    /// - Returns: ビデオレコード開始の結果を返す
    public func startRecording() -> Bool {
        
        var result: Bool = false
        
        if !recording {
            result = setUpWriter()
            if result {
                startedAt = Date()
                spaceDate = 0
                recording = true
                writing = false
                DispatchQueue.global().async {
                    self.displayLink = CADisplayLink.init(target: self, selector: #selector(self.drawFrame))
                    self.displayLink?.preferredFramesPerSecond = 30
                    self.displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
                    RunLoop.current.run()
                }
            }
        }
        
        return result
    }
    
    /// ビデオレコード停止
    public func stopRecording() {
        
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
        }
        isPause = false
        recording = false
        timer?.invalidate()
        timer = nil
        completeRecordingSession()
        cleanupWriter()
    }
    
    /// ビデオレコード一時停止
    public func pauseRecording() {
        
        objc_sync_enter(self)
        if recording {
            isPause = true
            recording = false
        }
        objc_sync_exit(self)
    }
    
    /// ビデオレコード再開始
    public func resumeRecording() {
        
        objc_sync_enter(self)
        if isPause {
            recording = true
            isPause = false
        }
        objc_sync_exit(self)
    }
    
    public func isStarted() -> Bool {
        
        return recording
    }
    
    public func isPaused() -> Bool {
        
        return isPause
    }
    
    // MARK: - private
    
    private func setUpWriter() -> Bool {
        
        var size: CGSize!
        let tmpsize = getCaptureSize()
        
        let scaleFactor = UIScreen.main.scale
        size = CGSize.init(width: tmpsize.width * scaleFactor, height: tmpsize.height * scaleFactor)
        
        // AVAssetWriter
        let fileUrl = NSURL.fileURL(withPath: filePath)
        do {
            try videoWriter = AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mp4)
        } catch let error as NSError {
            print("AVAssetWriter init fail. \(error)")
            return false
        }
        
        // AVAssetWriterInput
        let videoCompressionProps: Dictionary = [AVVideoAverageBitRateKey: NSNumber(value: self.videoBitrate),
                                                 AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                                 AVVideoExpectedSourceFrameRateKey: NSNumber(value: self.frameRate),
                                                 AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                                                 AVVideoAllowFrameReorderingKey: false
            ] as [String: Any]
        let videoSettings: Dictionary = [AVVideoCodecKey: AVVideoCodecH264,
                                         AVVideoWidthKey: NSNumber.init(value: Int(size.width)),
                                         AVVideoHeightKey: NSNumber.init(value: Int(size.height)),
                                         AVVideoCompressionPropertiesKey: videoCompressionProps] as [String : Any]
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        videoWriterInput?.mediaTimeScale = mediaTimeScale
        
        // AVAssetWriterInputPixelBufferAdaptor
        let bufferAttributes:Dictionary = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber.init(value: kCVPixelFormatType_32BGRA),
                                           kCVPixelBufferWidthKey as String: NSNumber.init(value: Int(size.width)),
                                           kCVPixelBufferHeightKey as String: NSNumber.init(value: Int(size.height))]
        avAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!,
                                                         sourcePixelBufferAttributes: bufferAttributes)
        videoWriter?.add(videoWriterInput!)
        videoWriter?.startWriting()
        videoWriter?.startSession(atSourceTime: CMTimeMake(value: 1, timescale: 1))
        
        // UIGraphicsGetCurrentContext
        UIGraphicsBeginImageContextWithOptions(tmpsize, true, 0)
        
        return true
    }
    
    private func writeVideoFrameAtTime(frameTime: CMTime, newImage: CGImage) {
        
        if !(videoWriterInput?.isReadyForMoreMediaData)! {
            print("Not ready for video data")
        } else {
            objc_sync_enter(self)
            
            var pixelBuffer: CVPixelBuffer? = nil
            if let cgImage = newImage.copy() {
                let image = cgImage.dataProvider!.data
                
                var status: Int32 = -1
                if let pixelBufferPool = avAdaptor?.pixelBufferPool {
                    status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                }
                if status != 0 {
                    print("Error creating pixel buffer:  status=\(status)")
                }
                // set image data into pixel buffer
                if let pb = pixelBuffer {
                    CVPixelBufferLockBaseAddress(pb, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                    let destPixels: UnsafeMutablePointer<UInt8> = (CVPixelBufferGetBaseAddress(pb)?.assumingMemoryBound(to: UInt8.self))!
                    CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels)
                    if status == 0 {
                        if let success = avAdaptor?.append(pb, withPresentationTime: frameTime), !success {
                            print("Warning:  Unable to write buffer to video")
                        }
                    }
                    // clean up
                    CVPixelBufferUnlockBaseAddress(pb, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                }
            }
            
            objc_sync_exit(self)
        }
    }
    
    private func completeRecordingSession() {
        if videoWriterInput == nil || videoWriter == nil {
            self.delegate?.videoRecordingComplete()
            return
        }
        
        videoWriterInput?.markAsFinished()
        videoWriter?.finishWriting {
            self.delegate?.videoRecordingComplete()
        }
    }
    
    @objc private func drawFrame() {
        if isPause {
            spaceDate = spaceDate + 1.0/Float(frameRate)
            return
        }
        
        performSelector(inBackground: #selector(self.getFrame), with: nil)
    }
    
    @objc private func getFrame() {
        
        if !writing {
            writing = true
            
            DispatchQueue.main.async { [weak self] in
                if let appDelegate = UIApplication.shared.delegate {
                    if let frame = UIApplication.shared.delegate?.window??.frame {
                        appDelegate.window??.drawHierarchy(in: frame, afterScreenUpdates: false)
                    }
                    let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
                    DispatchQueue.global(qos: .default).async {
                        if self?.recording == true, let startTime = self?.startedAt {
                            let millisElapsed = NSDate().timeIntervalSince(startTime) * 1000.0 - Double(((self?.spaceDate) ?? 0) * 1000.0)
                            self?.writeVideoFrameAtTime(frameTime: CMTimeMake(value: Int64.init(millisElapsed), timescale: 1000), newImage: cgImage!)
                        }
                        
                        self?.writing = false
                    }
                }
            }
            
        }
    }
    
    private func cleanupWriter() {
        
        avAdaptor = nil
        videoWriterInput = nil
        videoWriter = nil
        startedAt = nil
        UIGraphicsEndImageContext()
    }
    
    private func getCaptureSize() -> CGSize {
        let tmpsize = UIScreen.main.bounds.size
//        if self.is_iPhoneX() {
//            tmpsize.width = 384.0
//        }
//        if self.is_iPadPro10_5() {
//            tmpsize.width += 99
//        }
        return tmpsize
    }
}
