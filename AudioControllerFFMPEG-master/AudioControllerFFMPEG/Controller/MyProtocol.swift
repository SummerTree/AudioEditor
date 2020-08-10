//
//  MyProtocol.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 8/7/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

protocol TransformDataDelegate {
    
    func transform(url: URL, volume: Float, rate: Float)
    
    func transformQuality(quality: String)
    
    func transformMusicPath(path: String)
    
    func isSaveVideo(isSave: Bool)
    
    func isRemove(isRemove: Bool)
    
}
