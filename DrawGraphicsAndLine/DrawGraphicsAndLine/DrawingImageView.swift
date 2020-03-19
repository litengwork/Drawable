//
//  DrawingImageView.swift
//  DrawGraphicsAndLine
//
//  Created by ri on 2019/07/22.
//  Copyright © 2019 Lee. All rights reserved.
//

import UIKit

public enum CurrentColor {
    case Red
    case Blue
    case Green
}

public enum CurrentLineType {
    case Line
    case Arrow
    case Curve
}

public enum CurrentCustermType {
    case FourCorner
    case Yen
    case Polyline
}

public enum CurrentGraphicsType {
    case Round
    case Square
}

public protocol OnDrawingListener: class {
    func onSingleTap()
    func onDraw()
}

public class DrawingImageView: UIImageView {
    
    public var currentLineType: CurrentLineType = .Line
    public var currentGraphicsType: CurrentGraphicsType = .Square
    
    public var isTapShowCustermImg: Bool = false
    public var currentCustermType: CurrentCustermType = .FourCorner {
        didSet {
            round(currentCustermType)
        }
    }
    
    public var currentColor: CurrentColor = .Red
    public var currentStokeWidth: CGFloat = 1.0
    
    private let TOUCH_PIXEL_THRESHOLD: CGFloat = 1.0
    private let TOUCH_TIME_THRESHOLD: Float = 200 // milliseconds
    private let PADDING_FIGURE: Float = 50
    
    
    private weak var mListener: OnDrawingListener?
    private var mIsDrawable: Bool = false
    private var locusMode: Bool = false
    private var bezierPath: UIBezierPath?
    private var lastPoint: CGPoint?
    private var currentDrawNumber = [Int]()
    private var saveImageArray = [[UIImage]]()
    
    private var lastDrawImage:UIImage!
    
    
    private var tttt = [Int:UIImageView]()
    
    public var drawNumber: Int = 0 {
        didSet {
            self.image = saveImageArray[drawNumber][currentDrawNumber[drawNumber]]
            lastDrawImage = self.image
            mListener?.onDraw()
        }
    }
    
    public var drawNumberMax: Int = 1 {
        didSet {
            if (saveImageArray.count != drawNumberMax) {
                saveImageArray = [[UIImage]]()
                for i in 0..<drawNumberMax {
                    currentDrawNumber.append(0)
                    saveImageArray.append([UIImage]())
                    saveImageArray[i].append(self.image!)
                }
            }
        }
    }
    
    
    //    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    //        if (locusMode && !mIsDrawable) {
    //            return false
    //        } else {
    //            if (!self.frame.contains(point) && (point.y <= 0)) {
    //                return false
    //            } else {
    //                return true
    //            }
    //        }
    //    }
    //
    // MARK: - override UIImageView
    
    override init(image: UIImage?) {
        super.init(image: image)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    
    // MARK: - public
    
    public func setLocusMode(_ locusMode: Bool) {
        self.locusMode = locusMode
    }
    
    public func setDrawable(_ isDrawable: Bool) {
        mIsDrawable = isDrawable
    }
    
    public func setOnDrawingListener(_ listener: OnDrawingListener?) {
        mListener = listener
    }
    
    public func undo() {
        if currentDrawNumber[drawNumber] <= 0 {return}
        
        
        
        
        //
        //        self.image = saveImageArray[drawNumber][currentDrawNumber[drawNumber] - 1]
        //        lastDrawImage = self.image
        
        let img = saveImageArray[drawNumber][currentDrawNumber[drawNumber]]
        
        if img.size.width == 0 && img.size.height == 0 {
            if let imgview = tttt[currentDrawNumber[drawNumber]] {
                imgview.isHidden = true
            }
        } else {
            self.image = saveImageArray[drawNumber][currentDrawNumber[drawNumber] - 1]
            lastDrawImage = self.image
        }
        
        
        
        currentDrawNumber[drawNumber] -= 1
        mListener?.onDraw()
    }
    
    public func undoable() -> Bool {
        if currentDrawNumber[drawNumber] <= 0 {
            return false
        } else {
            return true
        }
    }
    public func redo() {
        if currentDrawNumber[drawNumber] + 1 > saveImageArray[drawNumber].count - 1 {return}
        
        let img = saveImageArray[drawNumber][currentDrawNumber[drawNumber] + 1]
        
        if img.size.width == 0 && img.size.height == 0 {
            if let imgview = tttt[currentDrawNumber[drawNumber] + 1] {
                imgview.isHidden = false
            }
        } else {
            self.image = saveImageArray[drawNumber][currentDrawNumber[drawNumber] + 1]
            lastDrawImage = self.image
        }
        
        
        
        currentDrawNumber[drawNumber] += 1
        mListener?.onDraw()
    }
    
    public func redoable() -> Bool {
        if currentDrawNumber[drawNumber] > saveImageArray[drawNumber].count - 2 {
            return false
        } else {
            return true
        }
    }
    
    public func clearFigure() {
        self.image = nil
        currentDrawNumber[drawNumber] = 0
        for imgview in tttt {
            let imv = imgview.value
            imv.removeFromSuperview()
        }
        tttt.removeAll()
        saveImageArray[drawNumber] = [UIImage]()
        prepareCanvas()
        saveImageArray[drawNumber].append(self.image!)
        lastDrawImage = nil
        mListener?.onDraw()
    }
    
    public func clearable() -> Bool {
        return redoable() || undoable()
    }
    
    private func commonInit() {
        
        self.isUserInteractionEnabled = true
        
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(DrawingImageView.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        self.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self,
                                             action: #selector(DrawingImageView.handlePinch(_:)))
        self.addGestureRecognizer(pinch)
        
        let tap = UITapGestureRecognizer.init(target: self,
                                              action: #selector(DrawingImageView.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
        prepareCanvas()
        
        for i in 0..<drawNumberMax {
            currentDrawNumber.append(0)
            saveImageArray.append([UIImage]())
            saveImageArray[i].append(self.image!)
        }
        
    }
    
    private func prepareCanvas() {
        let canvasSize = CGSize(width: self.frame.width * 2, height: self.frame.width * 2)
        let canvasRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        var firstCanvasImage = UIImage()
        UIColor.clear.setFill()
        UIRectFill(canvasRect)
        firstCanvasImage.draw(in: canvasRect)
        firstCanvasImage = UIGraphicsGetImageFromCurrentImageContext()!
        self.contentMode = .scaleAspectFit
        self.image = firstCanvasImage
        UIGraphicsEndImageContext()
    }
    
    private func drawToCanvas(_ canvas: UIImage, path:UIBezierPath, isImg: Bool? = nil){
        
        if isImg == nil  {
            UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
            
            if lastDrawImage != nil {
                lastDrawImage.draw(at: CGPoint(x: 0, y: 0))
            }
            
            var color = UIColor.red
            switch currentColor {
            case .Red:
                color = UIColor.red
                break
            case .Blue:
                color = UIColor.blue
                break
            case .Green:
                color = UIColor.green
                break
            }
            
            color.setStroke()
            path.stroke()
            
        } else {
            UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
            
            if lastDrawImage != nil {
                lastDrawImage.draw(at: CGPoint(x: 0, y: 0))
            }
        }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setShouldAntialias(true)
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y))
    }
    
    // MARK: - GestureRecognizer Handler
    
    @objc private func handleTap(_ pinchGesture: UITapGestureRecognizer) {
        mListener?.onSingleTap()
    }
    
    @objc private func handlePinch(_ pinchGesture: UIPinchGestureRecognizer) {
        if !mIsDrawable {
            return
        }
        
        guard let canvas = self.image else {
            print("pictureView.image not found")
            return
        }
        
        switch pinchGesture.state {
        case .began:
            
            if currentGraphicsType == .Round {
                bezierPath = UIBezierPath()
                guard let bzrPth = bezierPath else {
                    print("bezierPath Error")
                    return
                }
                bzrPth.lineWidth = currentStokeWidth
            }
            lastPoint = pinchGesture.location(in: self)
            
            break
            
        case .changed:
            
            if pinchGesture.numberOfTouches != 2 {
                print("numberOfTouches is not 2")
                return
            }
            
            let touchPoint1 = pinchGesture.location(ofTouch: 0, in: self)
            let touchPoint2 = pinchGesture.location(ofTouch: 1, in: self)
            
            if currentGraphicsType == .Round {
                
                guard let bzrPth = bezierPath else {
                    print("bezierPath Error")
                    return
                }
                
                bzrPth.removeAllPoints()
                let centerPoint = CGPoint(x: (min(touchPoint1.x, touchPoint2.x) + abs(touchPoint1.x - touchPoint2.x) / 2),
                                          y: (min(touchPoint1.y, touchPoint2.y) + abs(touchPoint1.y - touchPoint2.y) / 2))
                bzrPth.addArc(withCenter: centerPoint,
                              radius: CGPointDistance(from: touchPoint1, to: touchPoint2) / 2,
                              startAngle: CGFloat(0),
                              endAngle: CGFloat(Double.pi*2),
                              clockwise: true)
            } else if currentGraphicsType == .Square {
                
                let rect = CGRect(x: min(touchPoint1.x, touchPoint2.x),
                                  y: min(touchPoint1.y, touchPoint2.y),
                                  width: abs(touchPoint1.x - touchPoint2.x),
                                  height: abs(touchPoint1.y - touchPoint2.y))
                bezierPath = UIBezierPath(rect: rect)
                
                guard let bzrPth = bezierPath else {
                    print("bezierPath Error")
                    return
                }
                bzrPth.lineWidth = currentStokeWidth
            }
            drawToCanvas(canvas, path: bezierPath!)
            
            break
            
        case .ended:
            
            while currentDrawNumber[drawNumber] != saveImageArray[drawNumber].count - 1 {
                saveImageArray[drawNumber].removeLast()
            }
            currentDrawNumber[drawNumber] += 1
            saveImageArray[drawNumber].append(self.image!)
            if currentDrawNumber[drawNumber] != saveImageArray[drawNumber].count - 1 {
                print("index Error")
            }
            lastDrawImage = self.image
            mListener?.onDraw()
            
            break
            
        case .cancelled:
            mListener?.onDraw()
            break
            
        default:
            break
        }
    }
    
    @objc private func handlePan(_ panGesture: UIPanGestureRecognizer) {
        
        if !mIsDrawable {
            return
        }
        
        guard let canvas = self.image else {
            print("pictureView.image not found")
            return
        }
        
        let touchPoint = panGesture.location(in: self)
        
        switch panGesture.state {
        case .began:
            
            bezierPath = UIBezierPath()
            guard let bzrPth = bezierPath else {
                print("bezierPath Error")
                return
            }
            bzrPth.lineWidth = currentStokeWidth
            lastPoint = touchPoint
            bzrPth.move(to: lastPoint!)
            
            break
            
        case .changed:
            
            guard let bzrPth = bezierPath else {
                print("bezierPath Error")
                return
            }
            
            let newPoint = touchPoint
            if currentLineType == .Line {
                if (abs(newPoint.x - lastPoint!.x) >= TOUCH_PIXEL_THRESHOLD ||
                    abs(newPoint.y - lastPoint!.y) >= TOUCH_PIXEL_THRESHOLD) {
                    bzrPth.removeAllPoints()
                    bzrPth.move(to: lastPoint!)
                    bzrPth.addLine(to: newPoint)
                    drawToCanvas(canvas, path: bzrPth)
                }
            } else if currentLineType == .Curve {
                bzrPth.addCurve(to: newPoint, controlPoint1: newPoint, controlPoint2: newPoint)
                drawToCanvas(canvas, path: bzrPth)
            } else if currentLineType == .Arrow {
                if (abs(newPoint.x - lastPoint!.x) >= TOUCH_PIXEL_THRESHOLD ||
                    abs(newPoint.y - lastPoint!.y) >= TOUCH_PIXEL_THRESHOLD) {
                    bzrPth.removeAllPoints()
                    bzrPth.cgPath = arrow(from: lastPoint!, to: newPoint, tailWidth: 0.5, headWidth: 8, headLength: 8)
                    drawToCanvas(canvas, path: bzrPth)
                }
            }
            break
            
        case .ended:
            
            while currentDrawNumber[drawNumber] != saveImageArray[drawNumber].count - 1 {
                saveImageArray[drawNumber].removeLast()
            }
            currentDrawNumber[drawNumber] += 1
            saveImageArray[drawNumber].append(self.image!)
            if currentDrawNumber[drawNumber] != saveImageArray[drawNumber].count - 1 {
                print("index Error")
            }
            lastDrawImage = self.image
            mListener?.onDraw()
            
            break
            
        case .cancelled:
            mListener?.onDraw()
            break
            
        default:
            break
        }
        
    }
    
    @discardableResult
    func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> CGMutablePath {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
        let points: [CGPoint] = [
            p(0, tailWidth / 2),
            p(tailLength, tailWidth / 2),
            p(tailLength, headWidth / 2),
            p(length, 0),
            p(tailLength, -headWidth / 2),
            p(tailLength, -tailWidth / 2),
            p(0, -tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()
        
        return path
    }
    
    
    func round(_ type: CurrentCustermType) {
        while currentDrawNumber[drawNumber] != saveImageArray[drawNumber].count - 1 {
            saveImageArray[drawNumber].removeLast()
        }
        currentDrawNumber[drawNumber] += 1
        let tmpv = UIImageView()
        tmpv.frame = CGRect(x: 0, y: 0, width: 187, height: 187)
        tmpv.center = self.center
        switch type {
        case .FourCorner:
            tmpv.image = UIImage(named: "sijiao.png")
            break
        case .Yen:
            tmpv.image = UIImage(named: "yuan.png")
        case .Polyline:
            tmpv.frame.size = CGSize(width: 153, height: 381)
            tmpv.image = UIImage(named: "xian.png")
        }
        
        tmpv.tag = saveImageArray[drawNumber].count
        tmpv.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(tmpImgViewhandlePan(_:)))
        pan.maximumNumberOfTouches = 1
        tmpv.addGestureRecognizer(pan)
        self.addSubview(tmpv)
        saveImageArray[drawNumber].append(UIImage())
        tttt[currentDrawNumber[drawNumber]] = tmpv
        mListener?.onDraw()
    }
    
    
    @objc func tmpImgViewhandlePan(_ panGesture: UIPanGestureRecognizer) {
        let touchPoint = panGesture.location(in: self)
        guard let imgview = panGesture.view else { return }
        switch panGesture.state {
        case .began:
            self.setDrawable(false)
            break
        case .changed:
            imgview.center = touchPoint
            break
        case .ended:
            self.setDrawable(true)
            break
        case .cancelled:
            break
        default:
            break
        }
    }
    
}
