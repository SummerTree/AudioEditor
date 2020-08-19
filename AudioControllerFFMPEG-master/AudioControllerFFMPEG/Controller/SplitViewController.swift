//
//  SplitViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/22/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import AVFoundation
import ICGVideoTrimmer
import ZKProgressHUD

class SplitViewController: UIViewController {
    @IBOutlet weak var screen: UIView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    
    var delegate: TransformDataDelegate!
    
    var url: URL!
    var player = AVAudioPlayer()
    var startTime: CGFloat?
    var endTime: CGFloat?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    
    let fileManage = HandleOutputFile()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addScreenTap(screen: self.screen)
    }
    
//    func trimmerDoubleTap() {
//        let tap = UITapGestureRecognizer(target: self, action: #selector(trimmerTapped))
//        tap.numberOfTapsRequired = 2
//        trimmerView.addGestureRecognizer(tap)
//    }
//
//    @objc func trimmerTapped() {
//
//    }
    
    func addScreenTap(screen: UIView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        tap.numberOfTapsRequired = 1
        screen.addGestureRecognizer(tap)
    }
    
    @objc func screenTapped() {
        player.pause()
        self.dismiss(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        let asset = AVAsset(url: url)
        addAudioPlayer(with: url)
        initTrimmerView(asset: asset)
    }
    
    private func initTrimmerView(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.trimmerView.themeColor = .white
        self.trimmerView.showsRulerView = false
        self.trimmerView.thumbWidth = 12
        self.trimmerView.maxLength = CGFloat(player.duration)
        self.trimmerView.trackerColor = .white
        self.trimmerView.resetSubviews()
        setLabelTime()
    }
    
    // MARK: Add Audio player
    
    private func addAudioPlayer(with url: URL) {
        do {
            try player = AVAudioPlayer(contentsOf: url)
        } catch {
            print("Couldn't load file")
        }
        player.enableRate = true
        player.numberOfLoops = -1
        endTime = CGFloat(player.duration)
        startTime = 0
        initMedia()
        
    }
    
    func setLabelTime() {
        lblStartTime.text = CMTimeMakeWithSeconds(Float64(startTime!), preferredTimescale: 600).positionalTime
        lblEndTime.text = CMTimeMakeWithSeconds(Float64(endTime!), preferredTimescale: 600).positionalTime
        lblDuration.text = CMTimeMakeWithSeconds(Float64(endTime! - startTime!), preferredTimescale: 600).positionalTime
    }
    
    func initMedia() {
        if volume == nil {
            volume = 60.0
        }
        if rate == nil {
            rate = 4.0
        }
        player.rate = rate! * steps
        player.volume = volumeRate * volume!
    }
    
    // MARK: Playbacktime checker
    
    func startPlaybackTimeChecker() {
        stopPlaypbackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    func stopPlaypbackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        guard let start = startTime, let end = endTime else {
            return
        }
        
        let playbackTime = CGFloat(player.currentTime)
        trimmerView.seek(toTime: playbackTime)
        
        if Float(playbackTime) >= Float(end) {
            player.currentTime = Double(start)
            trimmerView.seek(toTime: start)
        }
    }
    
    // Change btPlay icon when pause
    func changeIconBtnPlay() {
        if player.isPlaying {
            btnPlay.setImage(UIImage(named: "icon_pause"), for: .normal)
        } else {
            btnPlay.setImage(UIImage(named: "icon_play"), for: .normal)
        }
    }
    
    // MARK: Handle IBAction
    
    @IBAction func save(_ sender: Any) {
        player.stop()
        self.dismiss(animated: true) {
            self.delegate.transform(url: self.url, volume: self.player.volume, rate: self.player.rate)
        }
    }
    
    @IBAction func back(_ sender: Any) {
        player.stop()
        self.dismiss(animated: true)
    }
    
       
    @IBAction func play(_ sender: Any) {
        player.currentTime = Double(startTime!)
        if player.isPlaying {
            player.pause()
            stopPlaypbackTimeChecker()
        } else {
            player.play()
            startPlaybackTimeChecker()
        }
        changeIconBtnPlay()
    }
    
    @IBAction func split(_ sender: Any) {
        player.pause()
        let name = Date().toString(dateFormat: "HH:mm:ss")
        let type = ".mp3" 
        let output = fileManage.createUrlInApp(name: "\(name)\(type)")
        
        let duration = endTime! - startTime!
        let cmd = "-i \(url.path) -ss \(startTime!) -t \(duration) -q:a 0 -map a \(output)"
        
        let queue = DispatchQueue(label: "queue")
        
        DispatchQueue.main.async {
            ZKProgressHUD.show()
        }
        
        queue.async {
            MobileFFmpeg.execute(cmd)
            self.url = output
            self.addAudioPlayer(with: self.url)
            DispatchQueue.main.async {
                ZKProgressHUD.dismiss()
                self.initTrimmerView(asset: AVAsset(url: self.url))
                ZKProgressHUD.showSuccess()
            }
        }
        
    }
    
}

extension SplitViewController: ICGVideoTrimmerDelegate {
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        
        player.pause()
        changeIconBtnPlay()
        
        player.currentTime = Double(startTime)
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
    
}

