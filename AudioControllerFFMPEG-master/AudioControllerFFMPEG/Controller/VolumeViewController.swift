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

protocol PassVolumeBackDelegate {
    func passVolumeBack(volume: Float)
}

class VolumeViewController: UIViewController {
    
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var sliderVolume: UISlider!

    
    var delegate: PassVolumeBackDelegate!
    var player = AVAudioPlayer()
    var path: String!
    
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        sliderVolume.value = volume
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let pathURL = URL(fileURLWithPath: path)
        
        super.viewDidAppear(animated)
        addAudioPlayer(with: pathURL)
        initTrimmerView(asset: AVAsset(url: pathURL))
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
        player.numberOfLoops = -1
        player.enableRate = true
        initMedia()
    }
    
    private func initTrimmerView(asset: AVAsset) {
           self.trimmerView.asset = asset
           self.trimmerView.delegate = self
           self.trimmerView.themeColor = .white
           self.trimmerView.showsRulerView = false
           self.trimmerView.maxLength = CGFloat(player.duration)
           self.trimmerView.trackerColor = .white
           self.trimmerView.thumbWidth = 10
           self.trimmerView.resetSubviews()
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
    
    @objc func itemDidFinishPlaying(_ notification: Notification){
        player.currentTime = 0
       }
    
    // MARK: Handle IBAction
    
    @IBAction func play(_ sender: Any) {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        changeIconBtnPlay()
    }
    
    
    @IBAction func saveChange(_ sender: Any) {
        self.delegate.passVolumeBack(volume: self.volume)
        self.navigationController?.popViewController(animated: true)
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
    }
}
