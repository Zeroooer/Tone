//
//  RecordViewController.swift
//  Tone
//
//  Created by Hisen on 2017/7/7.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import UIKit
import RealmSwift

enum ButtonState {
    case readyRecord
    case readyPlay
}

class RecordViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    let realm = try! Realm()
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var dropButton: UIButton!
    
    @IBOutlet weak var dropBtnOffset: NSLayoutConstraint!
    @IBOutlet weak var saveBtnOffset: NSLayoutConstraint!
    
    var playProgressPath: UIBezierPath?
    var shapeLayer: CAShapeLayer?
    
    var bouncePath: UIBezierPath?
    var bounceLayer: CAShapeLayer?
    var maskPath: UIBezierPath?
    var maskLayer: CAShapeLayer?
    
    // 画2空3 画6空4
    var lineDashPatterns = [[2, 3, 6, 4], [6, 3, 4, 4], [4, 3], [5, 4, 5, 3]]
    
    let audioManager = AudioManager(.recordAndPlay)
    
    var buttonState: ButtonState = .readyRecord {
        didSet {
            switch buttonState {
            case .readyRecord:
                recordButton.setImage(UIImage(named: "microphone-black-icon.png"), for: .normal)
                self.dropBtnOffset.constant = 5
                self.saveBtnOffset.constant = -5
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            case .readyPlay:
                recordButton.setImage(UIImage(named: "play-black-icon.png"), for: .normal)
                self.dropBtnOffset.constant = -95
                self.saveBtnOffset.constant = 95
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonState = .readyRecord
        audioManager.delegate = self
        configUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioManager.stopRecord()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: - IBActions
    
    @IBAction func recordBtnClicked(_ sender: Any) {
        if buttonState == .readyRecord {
            print("start record")
            self.audioManager.startRecord()
        }
    }
    
    
    @IBAction func recoedBtnCancelled(_ sender: Any) {
        switch buttonState {
        case .readyRecord:
            print("cancell record")
            self.audioManager.stopRecord()
            self.buttonState = .readyPlay
        case .readyPlay:
            if self.audioManager.audioPlayer != nil && (self.audioManager.audioPlayer?.isPlaying)! {
                return
            }
            self.audioManager.startPlay(nil)
            recordButton.setImage(UIImage(named: "stop-black-icon.png"), for: .normal)
        }
    }
    
    @IBAction func dropBtnClicked(_ sender: Any) {
        buttonState = .readyRecord
        self.audioManager.resetAudioManager(ifDelete: true)
    }
    
    @IBAction func saveBtnClicked(_ sender: Any) {
        saveAToneNote()
        
        buttonState = .readyRecord
        self.audioManager.resetAudioManager(ifDelete: false)
        //then dismiss
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveAToneNote() {
        let newToneNote = ToneNote()
        newToneNote.title = audioManager.audioFileName
        newToneNote.fileName = "\(audioManager.audioFileName).m4a"
        newToneNote.duration = audioManager.timeCount + 1
        try! realm.write {
            realm.add(newToneNote)
        }
    }
    
    deinit {
        print("deinit RecordVC")
    }
}

extension RecordViewController: PlayProgressDelegate {
    func updatePower(_ progress: Double) {
        print(progress)
        
        self.bouncePath = UIBezierPath(arcCenter: recordButton.center, radius: CGFloat(30 + 120 * progress), startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
        self.bounceLayer?.path = self.bouncePath?.cgPath
    }
    
    func updateProgress(_ progress: Double) {
        //        // 正向
        //        self.path = UIBezierPath(arcCenter: button.center, radius: button.frame.size.width / 2 - 3, startAngle: CGFloat(-Double.pi/2), endAngle: CGFloat(-Double.pi/2 + Double.pi*2*progress), clockwise: true)
        // 反向
        self.playProgressPath = UIBezierPath(arcCenter: recordButton.center, radius: recordButton.frame.size.width / 2 - 3, startAngle: CGFloat(Double.pi*3/2), endAngle: CGFloat(Double.pi*3/2 - Double.pi*2*progress), clockwise: true)
        self.shapeLayer?.path = self.playProgressPath?.cgPath
    }
    
    func playFinished(_ force:Bool) {
        self.shapeLayer?.path = nil
        if force {
            buttonState = .readyRecord
        } else {
            buttonState = .readyPlay
        }
    }
    
    func recordFinished(_ flag: Bool) {
        if flag {
            self.bounceLayer?.path = nil
        }
    }
}

// MARK - Private
extension RecordViewController {
    func configUI() {
        recordButton.layer.shadowColor = recordButton.backgroundColor?.cgColor
        recordButton.layer.shadowRadius = 5
        recordButton.layer.shadowOpacity = 0.5
        recordButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        dropButton.layer.shadowColor = dropButton.backgroundColor?.cgColor
        dropButton.layer.shadowRadius = 5
        dropButton.layer.shadowOpacity = 0.5
        dropButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        saveButton.layer.shadowColor = saveButton.backgroundColor?.cgColor
        saveButton.layer.shadowRadius = 5
        saveButton.layer.shadowOpacity = 0.5
        saveButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        
//        // 简陋版 wifi 遮罩
//        configRecoringAnimationLayer()
        // 散射遮罩
        configScatteringLayer()
    }
    
    func configProgressLayer() {
        shapeLayer = CAShapeLayer()
        shapeLayer?.fillColor = UIColor.clear.cgColor
        shapeLayer?.strokeColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 0.6).cgColor
        shapeLayer?.lineWidth = 6
        shapeLayer?.lineCap = "round"
        self.view.layer.addSublayer(self.shapeLayer!)
    }
    
    func configRecoringAnimationLayer() {
        maskLayer = CAShapeLayer()
        for i in 1...4 {
            let arcLayer = CAShapeLayer()
            arcLayer.fillColor = UIColor.clear.cgColor
            arcLayer.strokeColor = UIColor.white.cgColor
            arcLayer.lineWidth = 5
            arcLayer.lineCap = "round"
            let arcPath = UIBezierPath(arcCenter: recordButton.center, radius: recordButton.frame.size.width / 2 + CGFloat(8 * i), startAngle: CGFloat(-Double.pi*Double(32+i)/64), endAngle: CGFloat(-Double.pi*Double(32+i)/64 + Double.pi*Double(i)/32), clockwise: true)
            arcLayer.path = arcPath.cgPath
            maskLayer?.addSublayer(arcLayer)
        }
        
        bounceLayer = CAShapeLayer()
        bounceLayer?.fillColor = UIColor(red: 215 / 255, green: 218 / 255, blue: 229 / 255, alpha: 0.6).cgColor
        bounceLayer?.mask = self.maskLayer
        self.view.layer.addSublayer(bounceLayer!)
    }
    
    func configScatteringLayer() {
        maskLayer = CAShapeLayer()
        for i in 0..<360 {
            if i % 5 == 0 {
                var startLen = arc4random() % UInt32(52) + UInt32(48)
                startLen = max(50, min(54, startLen))
                let len = 50 + arc4random() % UInt32(40) + UInt32(10)
                let angle = Double.pi * 2 * Double(i) / 360
                let startX = Double(recordButton.center.x) + Double(startLen) * cos(angle)
                let startY = Double(recordButton.center.y) - Double(startLen) * sin(angle)
                let finalX = Double(recordButton.center.x) + Double(len) * cos(angle)
                let finalY = Double(recordButton.center.y) - Double(len) * sin(angle)
                let arcLayer = CAShapeLayer()
                arcLayer.strokeColor = UIColor.white.cgColor
                arcLayer.lineWidth = 2
                arcLayer.lineCap = "round"
                let arcPath = UIBezierPath()
                arcPath.move(to: CGPoint(x: startX, y: startY))
                arcPath.addLine(to: CGPoint(x: finalX, y: finalY))
                arcLayer.path = arcPath.cgPath
                arcLayer.lineDashPattern = randomElementFromArray(from: lineDashPatterns) as [NSNumber]
                maskLayer?.addSublayer(arcLayer)
            }
        }
        
        bounceLayer = CAShapeLayer()
        bounceLayer?.fillColor = UIColor(red: 215 / 255, green: 218 / 255, blue: 229 / 255, alpha: 0.6).cgColor
        bounceLayer?.mask = maskLayer
        self.view.layer.addSublayer(bounceLayer!)
    }
    
    func randomElementFromArray<T>(from array: Array<T>) -> T {
        let index: Int = Int(arc4random_uniform(UInt32(array.count)))
        return array[index]
    }
}
