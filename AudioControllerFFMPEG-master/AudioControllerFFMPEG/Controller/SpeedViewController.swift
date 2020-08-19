//
//  SpeedViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/14/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import AVFoundation
import ICGVideoTrimmer

class SpeedViewController: UIViewController {
    
    @IBOutlet weak var screen: UIView!
    @IBOutlet weak var sliderSpeed: UISlider!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    
    var url: URL!
    var player = AVAudioPlayer()
    var delegate: TransformDataDelegate!
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    var startTime: CGFloat?
    var endTime: CGFloat?
    
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliderSpeed.value = rate
        addScreenTap(screen: self.screen)
    }
    
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

        addAudioPlayer(with: url)
        initTrimmerView(asset: AVAsset(url: url))
        player.pause()
        changeIconBtnPlay()
    }
    
    func changeIconBtnPlay() {
        if player.isPlaying {
            btnPlay.setImage(UIImage(named: "icon_pause"), for: .normal)
        } else {
            btnPlay.setImage(UIImage(named: "icon_play"), for: .normal)
        }
    }
    
    // MARK: Add video player
    private func addAudioPlayer(with url: URL) {
        do {
            try player = AVAudioPlayer(contentsOf: url)
        } catch {
            print("Couldn't load file")
        }
        player.enableRate = true
        initMedia()
    }
    
    func initMedia() {
        player.rate = rate! * steps
        player.volume = volumeRate * volume!
    }
    
    private func initTrimmerView(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.trimmerView.themeColor = .white
        self.trimmerView.showsRulerView = false
        self.trimmerView.maxLength = CGFloat(player.duration)
        self.trimmerView.trackerColor = .white
        self.trimmerView.thumbWidth = 12
        self.trimmerView.resetSubviews()
        setLabelTime()
    }
    
    func setLabelTime() {
        lblStartTime.text = CMTimeMakeWithSeconds(Float64(startTime!), preferredTimescale: 600).positionalTime
        lblEndTime.text = CMTimeMakeWithSeconds(Float64(endTime!), preferredTimescale: 600).positionalTime
    }
    
    // MARK: Playback time checker
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
    
    
    // MARK: IBAction
    
    @IBAction func play(_ sender: Any) {
        if player.isPlaying {
            player.pause()
            stopPlaypbackTimeChecker()
        } else {
            player.play()
            startPlaybackTimeChecker()
        }
        changeIconBtnPlay()
    }
    
    @IBAction func changeSpeed(_ sender: Any) {
        rate = roundf(sliderSpeed.value)
        if rate == 0 || rate == 8 {
            sliderSpeed.value = rate
        } else {
            sliderSpeed.value = rate
        }
        player.rate = rate * steps
        changeIconBtnPlay()
    }
    
    
    @IBAction func back(_ sender: Any) {
        player.stop()
        self.dismiss(animated: true)
    }
    
    @IBAction func save(_ sender: Any) {
        player.stop()
        self.dismiss(animated: true) {
            self.delegate.transform(url: self.url, volume: self.player.volume, rate: self.player.rate)
        }
    }
}

extension SpeedViewController: ICGVideoTrimmerDelegate {
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        player.pause()
        changeIconBtnPlay()
        player.currentTime = Double(startTime)
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
    
    
}
