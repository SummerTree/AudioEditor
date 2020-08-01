//
//  DuplicateViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/14/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import ICGVideoTrimmer
import ZKProgressHUD


class DeleteViewController: UIViewController {
    
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    @IBOutlet weak var btnPlay: UIButton!
    
    var path:String!
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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        addAudioPlayer(with: URL(fileURLWithPath: path))
        initTrimmerView(asset: asset)
    }
    
    
    private func initTrimmerView(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.trimmerView.themeColor = .white
        self.trimmerView.showsRulerView = false
        self.trimmerView.maxLength = CGFloat(player.duration)
        self.trimmerView.trackerColor = .white
        self.trimmerView.resetSubviews()
        setLabelTime()
    }
    
    // MARK: Prepare audio player to trim audio
    
    /// Add  Audio/ Video Player for playerView
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
    
    
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
        
    }
    
    func stopPlaybackTimeChecker(){
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
    @IBAction func play(_ sender: Any) {
        player.currentTime = Double(startTime!)
        if player.isPlaying {
            player.pause()
            stopPlaybackTimeChecker()
        } else {
            player.play()
            startPlaybackTimeChecker()
        }
        changeIconBtnPlay()
    }
    
    @IBAction func saveChange(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
        player.currentTime = 0
        player.pause()
        changeIconBtnPlay()
    }
    
    @IBAction func deleteSelectedAudioFile(_ sender: Any) {
        
        let outputURL1 = fileManage.createUrlInApp(name: "File1.mp3")
        let outputURL2 = fileManage.createUrlInApp(name: "File2.mp3")
        
        let name = Date().toString(dateFormat: "HH:mm:ss")
        let type = ".mp3"
        
        let outputURL3 = fileManage.createUrlInApp(name: "\(name)\(type)")
        
        
        let duration = CGFloat(player.duration) - endTime!
        
        // -i audio.mp3 -ss 00:01:54 -to 00:06:53 -c copy output.mp3
        // -i input.mp4 -ss 00:01:00 -codec copy -t 60 output.mp4
        // -i sample.avi -ss 00:03:05 -t 00:00:45.0 -q:a 0 -map a sample.mp3 - cut audio from video
        let cmd = "-i \(path!) -ss 0 -t \(startTime!) -q:a 0 -map a \(outputURL1)"
        let cmd1 = "-i \(path!) -ss \(endTime!) -t \(duration) -q:a 0 -map a \(outputURL2)"
        let cmd2 = "-i concat:\(outputURL1)|\(outputURL2) -c copy \(outputURL3)"
        
        let queue = DispatchQueue(label: "queue")
        
        DispatchQueue.main.async {
            ZKProgressHUD.show()
        }
        
        queue.async {
            MobileFFmpeg.execute(cmd)
            MobileFFmpeg.execute(cmd1)
            MobileFFmpeg.execute(cmd2)
            let x = self.fileManage.saveToDocumentDirectory(url: outputURL3)
            self.addAudioPlayer(with: x)
            DispatchQueue.main.async {
                ZKProgressHUD.dismiss()
                self.initTrimmerView(asset: AVAsset(url: x))
                ZKProgressHUD.showSuccess()
            }
        }
    }
}


extension DeleteViewController: ICGVideoTrimmerDelegate {
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        
        player.pause()
        changeIconBtnPlay()
        
        player.currentTime = Double(startTime)
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
}
