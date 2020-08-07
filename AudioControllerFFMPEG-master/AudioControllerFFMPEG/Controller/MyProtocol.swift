//
//  MyProtocol.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 8/7/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

protocol TransformDataDelegate {
    func transformVolume(volume: Float)
    
    func transformRate(rate: Float)
    
    func transformQuality(quality: String)
    
    func transformMusicPath(path: String)
    
    func isSaveVideo(isSave: Bool)
    
    func transformDeleteMusic(url: URL)
}
