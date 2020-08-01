//
//  SpeedViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/14/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import AVFoundation

protocol PassSpeedBackDelegate {
    func passSpeedData(speed: Float)
}

class SpeedViewController: UIViewController {
    
    @IBOutlet weak var sliderSpeed: UISlider!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var playerView: UIView!
    
    var player = AVAudioPlayer()
    var delegate: PassSpeedBackDelegate!
    var path: String!
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliderSpeed.value = rate
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addAudioPlayer(with: URL(fileURLWithPath: path))
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
        player.numberOfLoops = -1
        player.enableRate = true
        initMedia()
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
    
    
    // MARK: IBAction
    
    @IBAction func play(_ sender: Any) {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        changeIconBtnPlay()
        print(player.rate)
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
    
    @IBAction func saveChange(_ sender: Any) {
        self.dismiss(animated: true) {
            self.delegate.passSpeedData(speed: self.rate)
        }
    }
}
