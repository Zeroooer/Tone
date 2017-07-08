//
//  AudioManager.swift
//  AudioDemo
//
//  Created by Hisen on 2017/7/2.
//  Copyright © 2017年 AppCoda. All rights reserved.
//

import Foundation
import AVFoundation

protocol PlayProgressDelegate: class {
    func updatePower(_ progress: Double)
    func updateProgress(_ progress: Double)
    func playFinished(_ force: Bool)
    func recordFinished(_ flag: Bool)
}

extension PlayProgressDelegate {
    func updatePower(_ progress: Double) {
//        print("implementation in extension")
    }
    
    func updateProgress(_ progress: Double) {
//        print("implementation in extension")
    }
    
    func playFinished(_ force: Bool) {
//        print("implementation in extension")
    }
    
    func recordFinished(_ flag: Bool) {
//        print("implementation in extension")
    }
}

enum DisplayLinkType {
    case record
    case play
}

enum AudioManagerType {
    case recordAndPlay
    case playBack
}

class AudioManager: NSObject {
    
    let audioSession = AVAudioSession.sharedInstance()
    
    var audioRecorder : AVAudioRecorder?
    var audioPlayer : AVAudioPlayer?
    
    var audioCreateTime : Date?
    
    var playDisplayLink: CADisplayLink?
    
    var recordDisplayLink: CADisplayLink?
    var lastStep: CFTimeInterval = 0.0
    var duration: CFTimeInterval = 0.0
    var timeOffset: CFTimeInterval = 0.0
    var timeCount: NSInteger = 0

    
    weak var delegate: PlayProgressDelegate?
    
    var audioFileName : String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY.MM.dd-HH:mm:ss"
        if let createTime = audioCreateTime {
            return dateFormatter.string(from: createTime)
        } else {
            audioCreateTime = Date()
            return dateFormatter.string(from: audioCreateTime!)
        }
    }
    
    var audioURL : URL! {
        try! FileManager.default.createDirectory(atPath: "\(NSHomeDirectory())/Documents/toneNote",
            withIntermediateDirectories: true, attributes: nil)
        print("\(audioFileName)")
        
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("toneNote/\(audioFileName).m4a")
        
    }
    
//    override init() {
//        super.init()
//        prepareRecord()
//    }
    
    init(_ managerType: AudioManagerType) {
        super.init()
        switch managerType {
        case .recordAndPlay:
            prepareRecord()
        default:
            break
        }
    }
    
    deinit {
        print("deinit AudioManager")
    }
    
    func resetAudioManager(ifDelete delete:Bool) {        
        audioPlayer?.stop()
        self.playDisplayLink?.invalidate()
        delegate?.playFinished(true)
        audioRecorder = nil
        audioPlayer = nil
        if delete {
            try! FileManager.default.removeItem(at: audioURL)
            audioCreateTime = nil
            prepareRecord()
        }
    }
    
    func prepareRecord() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            
            let recorderSetting: [String: AnyObject] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
                AVSampleRateKey: 44100.0 as AnyObject,
                AVNumberOfChannelsKey: 2 as AnyObject,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue as AnyObject
            ]
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: recorderSetting)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            fatalError("error: \(error)")
        }
    }
    
    func startRecord() {
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                do {
                    try audioSession.setActive(true)
                    recorder.record()
                } catch {
                    fatalError("error: \(error)")
                }
            } else {
                recorder.pause()
            }
        }
        createDisplayLink(.record)
    }
    
    func stopRecord() {
        if let recorder = audioRecorder {
            if recorder.isRecording {
                recorder.stop()
                recordDisplayLink?.invalidate()
                
                do {
                    try audioSession.setActive(false)
                } catch {
                    fatalError("error: \(error)")
                }
            }
        }
    }
    
    func startPlay(_ audioURL: URL?) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
            }
        }

        do {
            if let url = audioURL {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            } else {
                audioPlayer = try AVAudioPlayer(contentsOf: self.audioURL!)
            }
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.play()
            createDisplayLink(.play)
        } catch {
            fatalError("error: \(error)")
        }
    }
    
    func stopPlay() {
        audioPlayer?.stop()
    }
    
    func createDisplayLink(_ displaylinkType: DisplayLinkType) {
        switch displaylinkType {
        case .record:
            self.duration = 1.0
            self.timeOffset = 0.0
            self.timeCount = 0
            self.recordDisplayLink?.invalidate()
            self.lastStep = CACurrentMediaTime()
            self.recordDisplayLink = CADisplayLink(target: self, selector: #selector(step))
            self.recordDisplayLink!.add(to: .current, forMode: .commonModes)
        case .play:
            self.playDisplayLink?.invalidate()
            self.playDisplayLink = CADisplayLink(target: self, selector: #selector(step))
            self.playDisplayLink!.add(to: .current, forMode: .commonModes)
        }
    }
    
    func step(displaylink: CADisplayLink) {
        if displaylink == self.playDisplayLink {
            
//            // 播放进度回调
//            let progress = (audioPlayer?.currentTime)! / (audioPlayer?.duration)!
//            delegate?.updateProgress(Double(progress))
            
            self.audioPlayer?.updateMeters()
            var power = self.audioPlayer?.averagePower(forChannel: 0)
            power = power! + 110.0
            
            var dB = 0
            if (Double(power!) < 0.0) {
                dB = 0;
            } else if (Double(power!) < 40.0) {
                dB = (Int)(power! * 0.875);
            } else if (Double(power!) < 100.0) {
                dB = (Int)(power! - 15);
            } else if (Double(power!) < 110.0) {
                dB = (Int)(power! * 2.5 - 165);
            } else {
                dB = 110;
            }
            delegate?.updatePower(Double(dB) / 160.0)
        } else if displaylink == self.recordDisplayLink {
            //更新测量值
            self.audioRecorder?.updateMeters()
            var power = self.audioRecorder?.averagePower(forChannel: 0)
            power = power! + 110.0
            
            var dB = 0
            if (Double(power!) < 0.0) {
                dB = 0;
            } else if (Double(power!) < 40.0) {
                dB = (Int)(power! * 0.875);
            } else if (Double(power!) < 100.0) {
                dB = (Int)(power! - 15);
            } else if (Double(power!) < 110.0) {
                dB = (Int)(power! * 2.5 - 165);
            } else {
                dB = 110;
            }
            delegate?.updatePower(Double(dB) / 160.0)
            
            // timing
            let thisStep = CACurrentMediaTime()
            let stepDuration = thisStep - self.lastStep
            self.lastStep = thisStep
            //update time offset
            self.timeOffset = min(self.timeOffset + stepDuration, self.duration)
            if self.timeOffset == 1 {
                self.timeCount += 1
                self.timeOffset = 0
            }
        }
    }
    
}

// MARK: AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording")
        recordDisplayLink?.invalidate()
        delegate?.recordFinished(flag)
    }
}

// MARK: AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audioPlayerDidFinishPlaying")
        playDisplayLink?.invalidate()
        delegate?.playFinished(false)
    }
}
