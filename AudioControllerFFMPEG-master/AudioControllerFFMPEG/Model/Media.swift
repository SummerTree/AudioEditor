//
//  Media.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 8/5/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}

struct ArrAudio {
    var player: AVAudioPlayer
    var delayTime: CGFloat
}
