//
//  MyProtocol.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 8/7/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import AVFoundation

protocol TransformDataDelegate {
    
    func transform(url: URL, volume: Float, rate: Float)
    
    func transformMusicPath(path: String)
    
    func isRemove(isRemove: Bool)
    
    func delayTime(delayTime: CGFloat)
    
    func isGetMusic(state: Bool)
}
