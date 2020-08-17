//
//  VolumeViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/14/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import AVFoundation
import ICGVideoTrimmer


class VolumeViewController: UIViewController {
    
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    @IBOutlet weak var screen: UIView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var sliderVolume: UISlider!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    
    var delegate: TransformDataDelegate!
    var player = AVAudioPlayer()
    var url: URL!
    
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    var startTime: CGFloat?
    var endTime: CGFloat?
    
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var isVideo: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliderVolume.value = volume
        
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
    
    private func addAudioPlayer(with url: URL) {
        do {
            try player = AVAudioPlayer(contentsOf: url)
        } catch {
            print("Couldn't load file")
        }
        if !isVideo {
            player.numberOfLoops = -1
            player.enableRate = true
        }
        endTime = CGFloat(player.duration)
        startTime = 0
        initMedia()
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
    
    func initMedia() {
        
        if !isVideo {
            player.rate = rate! * steps
        }
        player.volume = volumeRate * volume!
    }
    
    func setLabelTime() {
        lblStartTime.text = CMTimeMakeWithSeconds(Float64(startTime!), preferredTimescale: 600).positionalTime
        lblEndTime.text = CMTimeMakeWithSeconds(Float64(endTime!), preferredTimescale: 600).positionalTime
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification){
        player.currentTime = 0
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
    
    // MARK: Handle IBAction
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
    
    
    @IBAction func screenPressed(_ sender: Any) {
        player.stop()
        self.dismiss(animated: true)
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
    
    @IBAction func changeVolume(_ sender: Any) {
        sliderVolume.value = roundf(sliderVolume.value)
        volume = sliderVolume.value
        player.volume = volume * volumeRate
    }
    
    
    @IBAction func volumeTapped(_ sender: Any) {
        if volume > 0 {
            volume = 0
            sliderVolume.value = volume
            player.volume = volume
        } else {
            volume = 100
            sliderVolume.value = volume
            player.volume = volume * volumeRate
        }
    }
}

extension VolumeViewController: ICGVideoTrimmerDelegate {
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        player.pause()
        changeIconBtnPlay()
        player.currentTime = Double(startTime)
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
}
