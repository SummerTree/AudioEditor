//
//  MediaModel.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 8/1/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import AVFoundation
import UIKit

extension AVPlayer {

    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}

class MediaModel {
    
    var audioPlayer = AVAudioPlayer()
    var videoPlayer = AVPlayer()
    var volume: Float!
    var volumeRate: Float!
    var steps: Float!
    var rate: Float!
    var path: String!
    var asset: AVAsset!
    
    func setPath(path: String) {
        self.path = path
    }
    
    
   func addVieoPlayer(asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        videoPlayer = AVPlayer(playerItem: playerItem)
        let layer: AVPlayerLayer = AVPlayerLayer(player: videoPlayer)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
    }
    
    func addAudioPlayer() {
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        } catch {
            print("Couldn't load file")
        }
        audioPlayer.enableRate = true
        audioPlayer.numberOfLoops = -1
        initMedia()
    }
    
    private func initMedia() {
        if volume == nil {
            volume = 60.0
        }
        if rate == nil {
            rate = 4.0
        }
        audioPlayer.volume = volume * volumeRate
        audioPlayer.rate = rate * steps
    }
}
