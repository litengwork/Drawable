//
//  ViewController.swift
//  DrawGraphicsAndLine
//
//  Created by ri on 2019/07/22.
//  Copyright © 2019 Lee. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController, OnDrawingListener, VideoRecorderDelegate {
    
    @IBOutlet weak var drawLayout: DrawingImageView!

    @IBOutlet weak var greenBtn: UIButton!
    @IBOutlet weak var redBtn: UIButton!
    @IBOutlet weak var blueBtn: UIButton!
    @IBOutlet weak var squareImg: UIImageView!
    @IBOutlet weak var lineImg: UIImageView!
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var redoBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var activty: UIActivityIndicatorView!
    
    @IBOutlet weak var currentSelectView: UIView!
    @IBOutlet weak var currentSelectViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentSelectedImg: UIImageView!
    
    @IBOutlet weak var aLabel: UILabel!
    //
    @IBOutlet weak var subToolView3: UIView!
    @IBOutlet weak var subToolView2: UIView!
    @IBOutlet weak var subToolView1: UIView!
    @IBOutlet weak var subToolView1Constraint: NSLayoutConstraint!
    @IBOutlet weak var subToolView2Constraint: NSLayoutConstraint!
    @IBOutlet weak var subToolView3Constraint: NSLayoutConstraint!
    
    @IBOutlet weak var drawingImgViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recBtn: UIButton!
    
    let vidorec = VideoRecord()
    var destFile = ""
    fileprivate var mScreenRecController: ScreenRecController!

    fileprivate var isRec: Bool = false

    private var isTapShowCustermImg: Bool = false {
        didSet {
            if isTapShowCustermImg {
                drawLayout.isTapShowCustermImg = true
                drawLayout.setDrawable(false)
            } else {
                drawLayout.isTapShowCustermImg = false
                drawLayout.setDrawable(true)
            }
        }
    }
    
    private var currentCustemType: CurrentCustermType = .FourCorner {
        didSet {
            drawLayout.currentCustermType = currentCustemType
        }
    }
    
    
    
    private var changeBackColor: Bool = false {
        didSet {
            if changeBackColor {
                self.view.backgroundColor = .black
            } else {
                self.view.backgroundColor = .white
            }
        }
    }

    private var currentLineType: CurrentLineType = .Line {
        didSet {
            drawLayout.currentLineType = currentLineType
            drawLayout.setDrawable(true)
        }
    }
    
    private var currentGraphicsType: CurrentGraphicsType = .Square {
        didSet {
            drawLayout.currentGraphicsType = currentGraphicsType
            drawLayout.setDrawable(true)
        }
    }
    
    private var currentStokeWidth: CGFloat = 1.0 {
        didSet {
            drawLayout.currentStokeWidth = currentStokeWidth
            drawLayout.setDrawable(true)
        }
    }
    
    private var currentColor: CurrentColor = .Red {
        didSet {
            switch currentColor {
            case .Red:
                currentSelectedImg.backgroundColor = .red
            case .Blue:
                currentSelectedImg.backgroundColor = .blue
            case .Green:
                currentSelectedImg.backgroundColor = .green
            }
            showCurrentSelectImgView()
            drawLayout.currentColor = currentColor
            drawLayout.setDrawable(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
//        undoBtn.isHidden = true
//        redoBtn.isHidden = true
//        deleteBtn.isHidden = true
        
        initBasic()
       
        drawLayout.drawNumberMax = 4
        drawLayout.currentColor = .Red
        drawLayout.setOnDrawingListener(self)
        drawLayout.setLocusMode(true)
        drawLayout.setDrawable(true)

        mScreenRecController = ScreenRecController()
        mScreenRecController.setEventListener(self)
        activty.stopAnimating()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(self.viewWillEnterForeground(_:)),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(self.viewDidEnterBackground(_:)),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
    }
    
    func initBasic() {
        redBtn.isSelected = true
        subToolView1.isHidden = true
        subToolView2.isHidden = true
        subToolView3.isHidden = true
        subToolView1Constraint.constant = 0.0
        subToolView2Constraint.constant = 0.0
        subToolView3Constraint.constant = 0.0
        drawingImgViewConstraint.constant = 1.0
        undoBtn.isEnabled = false
        redoBtn.isEnabled = false
        deleteBtn.isEnabled = false
        currentSelectedImg.backgroundColor = .red
        self.currentSelectView.isHidden = false
        self.currentSelectViewConstraint.constant = 10.0
        self.view.layoutIfNeeded()
//        showCurrentSelectImgView()
    }
    
    func onSingleTap() {
        
    }
    
    func onDraw() {
        updateDrawTool()
    }
    
    func showCurrentSelectImgView() {
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseIn, animations: {
            self.currentSelectView.isHidden = false
            self.currentSelectViewConstraint.constant = 10.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func currentImgAction(_ sender: Any) {
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseIn, animations: {
            self.currentSelectViewConstraint.constant = 70.0
            self.view.layoutIfNeeded()
            self.currentSelectView.isHidden = true
        }, completion: nil)
    }
    
    @IBAction func slideAction(_ sender: UISlider) {
        currentStokeWidth = CGFloat(sender.value)
        print(sender.value)
    }
    
    @IBAction func wbAction(_ sender: UIButton) {
        changeBackColor = !changeBackColor
    }
    
    
}

// BASE ACTION
extension ViewController {
    
    @IBAction func greenBtnAction(_ sender: UIButton) {
        redBtn.isSelected = false
        blueBtn.isSelected = false
        currentColor = .Green
        greenBtn.isSelected = true        
    }
    
    @IBAction func blueBtnAction(_ sender: UIButton) {
        redBtn.isSelected = false
        greenBtn.isSelected = false
        currentColor = .Blue
        blueBtn.isSelected = true
    }
    
    @IBAction func redBtnAction(_ sender: UIButton) {
        greenBtn.isSelected = false
        blueBtn.isSelected = false
        currentColor = .Red
        redBtn.isSelected = true
    }
    
    @IBAction func squareAction(_ sender: UITapGestureRecognizer) {
        dismissSubToolView()
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
            self.subToolView1.isHidden = false
            self.subToolView1Constraint.constant = 50.0
            self.drawingImgViewConstraint.constant = 51.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func lineAction(_ sender: UITapGestureRecognizer) {
        dismissSubToolView()
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
            self.subToolView2.isHidden = false
            self.subToolView2Constraint.constant = 50.0
            self.drawingImgViewConstraint.constant = 51.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func aBtnAction(_ sender: UITapGestureRecognizer) {
        dismissSubToolView()
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
            self.subToolView3.isHidden = false
            self.subToolView3Constraint.constant = 50.0
            self.drawingImgViewConstraint.constant = 51.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func dismissSubToolView()  {
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: {
            self.subToolView1Constraint.constant = 0.0
            self.subToolView2Constraint.constant = 0.0
            self.subToolView3Constraint.constant = 0.0
            self.drawingImgViewConstraint.constant = 1.0
            self.subToolView1.isHidden = true
            self.subToolView2.isHidden = true
            self.subToolView3.isHidden = true
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func subToolViewTapAction(_ sender: UITapGestureRecognizer) {
        dismissSubToolView()
        switch sender.view?.tag {
        
        case 1006:
            aLabel.text = (sender.view as! UILabel).text ?? ""
            currentCustemType = .FourCorner
            break
        case 1007:
            aLabel.text = (sender.view as! UILabel).text ?? ""
            currentCustemType = .Yen
            break
        case 1008:
            aLabel.text = (sender.view as! UILabel).text ?? ""
            currentCustemType = .Polyline
            break
        case 1004:
            currentGraphicsType = .Square
            squareImg.image = (sender.view as! UIImageView).image
            break
        case 1005:
            currentGraphicsType = .Round
            squareImg.image = (sender.view as! UIImageView).image
            break
        case 1001:
            currentLineType = .Line
            lineImg.image = (sender.view as! UIImageView).image
            break
        case 1002:
            currentLineType = .Curve
            lineImg.image = (sender.view as! UIImageView).image
            break
        case 1003:
            currentLineType = .Arrow
            lineImg.image = (sender.view as! UIImageView).image
            break
        default:
            break
        }
        
        
    }
    
    
}

// undo redo delete
extension ViewController {
    
    fileprivate func updateDrawTool() {
//        undoBtn.isHidden = !drawLayout.undoable()
//        redoBtn.isHidden = !drawLayout.redoable()
//        deleteBtn.isHidden = !drawLayout.clearable()
        undoBtn.isEnabled = drawLayout.undoable()
        redoBtn.isEnabled = drawLayout.redoable()
        deleteBtn.isEnabled = drawLayout.clearable()
    }
    
    @IBAction func undoBtnAction(_ sender: UIButton) {
        let feedBack = UIImpactFeedbackGenerator(style: .light)
        feedBack.impactOccurred()
        drawLayout.undo()
    }
    
    @IBAction func redoBtnAction(_ sender: Any) {
        let feedBack = UIImpactFeedbackGenerator(style: .light)
        feedBack.impactOccurred()
        drawLayout.redo()
    }
    
    @IBAction func deleteBtnAction(_ sender: Any) {
        let feedBack = UIImpactFeedbackGenerator(style: .light)
        feedBack.impactOccurred()
        drawLayout.clearFigure()
    }
}

// REC Action
extension ViewController {
    
    @IBAction func recBtnAction(_ sender: Any) {
        recBtn.isSelected = !recBtn.isSelected
        if recBtn.isSelected {
            showSheet(with: recBtn, performaceType: {
                self.mScreenRecController.getScreenRecordingPermission { (isSuccess) in
                    if isSuccess {
                        self.mScreenRecController.start()
                    }
                }

            }, filesizeType: {
                // Start
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmm"
                let now = Date()
                let nowClockString = formatter.string(from: now)
                let fileName = nowClockString + ".mp4"
                self.destFile = NSHomeDirectory() + "/Library/" + fileName
                self.vidorec.filePath = self.destFile
                self.vidorec.delegate = self
                if self.vidorec.startRecording() {
                    print("START")
                }

            })
        } else {
            if isRec {
                activty.startAnimating()
                mScreenRecController.pause()
            }  else {
                // stop
                vidorec.stopRecording()
            }
        }
    }
    
    func videoRecordingComplete() {
        print(NSHomeDirectory() + "/Library/")
        
        showAlert(self, "REC DONE") { (_) in
            self.performSegue(withIdentifier: "showAvPlayer", sender: nil)
        }
    }
}

// PREPARE
extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAvPlayer" {
            let destination = segue.destination as! AVPlayerViewController
            let url = URL(fileURLWithPath: destFile)
            destination.player = AVPlayer(url: url)
            destination.player?.play()
        }
    }
}

extension UIViewController {
    func showAlert(_ vc: UIViewController, _ msg: String, okHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okaction = UIAlertAction(title: "OK", style: .default, handler: okHandler)
        alert.addAction(okaction)
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }

    fileprivate func showSheet(with sourceView: UIView, performaceType: @escaping() -> Void, filesizeType: @escaping() -> Void) {
        let sheet = UIAlertController(title: "Selected", message: nil, preferredStyle: .actionSheet)
        let performaceAction = UIAlertAction(title: "Performance", style: .default) { (_) in
            performaceType()
        }
        let filesizeAction = UIAlertAction(title: "Default", style: .default) { (_) in
            filesizeType()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        sheet.addAction(performaceAction)
        sheet.addAction(filesizeAction)
        sheet.addAction(cancelAction)
        if let vc = sheet.popoverPresentationController{
            vc.sourceView = sourceView
            vc.sourceRect = CGRect(x: sourceView.center.x, y: sourceView.frame.midY, width: 0, height: 0)
        }
        DispatchQueue.main.async {
            self.present(sheet, animated: true, completion: nil)
        }
    }

}
extension ViewController {

    @objc func viewWillEnterForeground(_ notification: Notification?) {

    }

    @objc func viewDidEnterBackground(_ notification: Notification?) {
        if isRec {
            if let alertcontroller = self.presentedViewController as? UIAlertController, alertcontroller.message == "終了しますか？" {
                alertcontroller.dismiss(animated: false, completion: nil)
                mScreenRecController.stop()
            } else {
                mScreenRecController.stopWithBackground()
            }
        }
    }
}

extension ViewController: ScreenRecControllerDelegate {
    func onRecPause() {
        DispatchQueue.main.async {
            self.activty.stopAnimating()
            self.showAlert(title: "終了しますか？", ishowcancel: true, confirm: {
                self.activty.startAnimating()
                self.mScreenRecController.stop()
            }) {
                self.mScreenRecController.resume()
            }
        }
    }

    func onRecStart() {
        DispatchQueue.main.async {
            self.isRec = true
            self.recBtn.setTitle("Pause", for: .normal)
        }
    }

    func onRecComplete(path: String) {
        DispatchQueue.main.async {
            self.activty.stopAnimating()
            self.isRec = false
            self.recBtn.setTitle("START", for: .normal)
            self.mScreenRecController._release()
            self.destFile = ""
            self.destFile = path
            self.showAlert(self, path) { (_) in
                self.performSegue(withIdentifier: "showAvPlayer", sender: nil)
            }
        }
    }

    func onRecFail(with error: ScreenRecError) {
        DispatchQueue.main.async {
            self.activty.stopAnimating()
            self.isRec = false
            self.recBtn.setTitle("START", for: .normal)
            self.mScreenRecController._release()
            self.showAlert(title: error.rawValue)
        }
    }

    func onUpdateRecTime(with sec: Int) {
        DispatchQueue.main.async {

        }
    }
}

extension UIViewController {
    func showAlert(title: String = "", ishowcancel: Bool = false, confirm: (() -> Void)? = nil, cancel: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            confirm?()
        }
        alert.addAction(action)
        if ishowcancel {
            let action1 = UIAlertAction(title: "Cancel", style: .destructive) { _ in
                cancel?()
            }
            alert.addAction(action1)
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension Int {
    func formatSecStr() -> String {
        let seconds = self % 60
        let minutes = (self / 60) % 60
        let hours = (self / 60 / 60) % 60
        return NSString.init(format: "%02d : %02d : %02d", hours, minutes, seconds) as String
    }
}
