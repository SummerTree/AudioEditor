//
//  ViewController.swift
//  FFmpegExample
//
//  Created by Apple on 7/13/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class PBViewController: UIViewController, AVAudioRecorderDelegate, MPMediaPickerControllerDelegate {
    
    var audioURL:URL? = nil
    var recordURL:URL?
    var videoURL:URL?
    var mergeURL:URL?
    var arr = [ModelItem]()
    var arrURL = [URL]()
    var songDetail = [Song]()
    
    @IBOutlet weak var videoPreviewLayer: UIView!
    @IBOutlet weak var mergebtn: UIButton!
    @IBOutlet weak var recordbtn: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var collectionView2: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    var player: AVPlayer!
    var playerLayer = AVPlayerLayer()
    var audioPlayer: AVAudioPlayer?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var mediaPicker: MPMediaPickerController?
    var myMusicPlayer: MPMusicPlayerController?
    
    var isPlay = false
    var isRecord = false
    var playingState = "Play"
    var recordNum = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        collectionView2.delegate = self
        collectionView2.dataSource = self
        createAudioSession()
        playVideo()
        initCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if audioURL != nil {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL!)
            } catch {
                print("Cannot play the file")
            }
            collectionView2.reloadData()
        }
        if arrURL.count != 0 {
            print("List URL: ")
            for i in 0..<arrURL.count {
                print(arrURL[i])
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player.pause()
        if isPlay {
            audioPlayer?.stop()
        }
    }
    
    func initCollectionView() {
        collectionView2.register(UINib(nibName: "ButtonCell", bundle: nil), forCellWithReuseIdentifier: "ButtonCell")
        arr.append(ModelItem(title: "Music", image: "Music"))
        arr.append(ModelItem(title: "Itunes", image: "Itunes"))
        arr.append(ModelItem(title: "Record", image: "Record"))
        arr.append(ModelItem(title: "Volume", image: "icon_sound"))
        arr.append(ModelItem(title: "Speed", image: "icon_speed"))
        arr.append(ModelItem(title: "Delete", image: "icon_trash"))
        arr.append(ModelItem(title: "Split", image: "icon_split"))
        arr.append(ModelItem(title: "Duplicate", image: "icon_duplicate"))
        arr.append(ModelItem(title: "Config", image: "icon_quality"))
    }
    
    // Create audio session
    func createAudioSession(){
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,mode:.moviePlayback ,options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    // Play mp4 video
    func playVideo() {
        //        let moviePath = Bundle.main.path(forResource: "bunny", ofType: "mp4")
        //        if let path = moviePath {
        //            videoURL = URL(fileURLWithPath: path)
        //            self.player = AVPlayer(url: videoURL!)
        //            self.avpController = AVPlayerViewController()
        //            self.avpController.player = self.player
        //            avpController.view.frame = videoPreviewLayer.bounds
        //            self.addChild(avpController)
        //            self.videoPreviewLayer.addSubview(avpController.view)
        //        }
        guard let path = Bundle.main.path(forResource: "bunny", ofType:"mp4") else {
            debugPrint("bunny.mp4 not found")
            return
        }
        videoURL = URL(fileURLWithPath: path)
        self.player = AVPlayer(url: videoURL!)
        self.playerLayer = AVPlayerLayer()
        self.playerLayer.player = self.player
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        playerLayer.frame = videoPreviewLayer.bounds
        self.videoPreviewLayer!.layer.addSublayer(playerLayer)
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification){
        player.seek(to: CMTime.zero)
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        btnPlayPause.setBackgroundImage(UIImage(named: "Play"), for: .normal)
    }
    
    // Remove Observer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
//    @IBAction func PlayPauseVideo(_ sender: Any) {
//        if audioPlayer != nil {
//            if !player.isPlaying {
//                playAudioFile()
//                player.play()
//                isPlay = true
//                btnPlayPause.setBackgroundImage(UIImage(named: "Pause"), for: .normal)
//            } else{
//                audioPlayer!.pause()
//                player.pause()
//                isPlay = false
//                btnPlayPause.setBackgroundImage(UIImage(named: "Play"), for: .normal)
//            }
//        } else {
//            print("Can't find audio!")
//        }
//
//    }
    
    func playAudioFile(){
        audioPlayer!.prepareToPlay()
        audioPlayer!.play()
    }
    
    //  Merge audio and video
    func mergeFileURL() -> URL {
        print("Link: \(audioURL!)")
        let st = "-i ﻿\(audioURL!)"//" -i \(audioURL!) -c:v copy -c:a aac \(getFileUrl())"
        //ffmpeg -i video.mp4 -i audio.wav -c:v copy -c:a aac output.mp4
        
        MobileFFprobe.execute(st)
        return getFileUrl()
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileUrl() -> URL
    {
        let filename = "mergevideo.mp4"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    //MARK: RECORD AUDIO
    
    // Get permission
    func recordPermission(){
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { granted in
                if granted {
                    print("Permission success")
                } else {
                    print("Permission denied")
                }
            }        } catch {
                // failed to record!
                print("Permission fail")
        }
    }
    
    func startRecord(){
        let fileName = "recordFile\(recordNum + 1).m4a"
        recordNum += 1
        recordURL = getDocumentsDirectory().appendingPathComponent(fileName)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do{
            audioRecorder = try AVAudioRecorder(url: recordURL!, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch{
            finishRecord(success: false)
        }
    }
    
    func finishRecord(success: Bool){
        audioRecorder.stop()
        audioRecorder = nil
        if success {
            arrURL.append(recordURL!)
            print(recordURL!)
            tableView.reloadData()
            collectionView2.reloadData()
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: recordURL!)
            } catch {
                print("Cannot create AVAudioPlayer")
            }
        } else{
            print("Record failed")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecord(success: false)
        }
    }
    
    //MARK: GET ITUNES MUSIC
    
    func displayMediaPickerAndPlayItem(){
        mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        
        if let picker = mediaPicker{
            
            print("Successfully instantiated a media picker")
            picker.delegate = self
            view.addSubview(picker.view)
            present(picker, animated: true, completion: nil)
            //            playItunesItem()
        } else {
            print("Could not instantiate a media picker")
        }
    }
    
    func playItunesItem(){
        // All
        let mediaItems = MPMediaQuery.songs().items!
        
        let mediaCollection = MPMediaItemCollection(items: mediaItems)
        let items = mediaCollection.items
        for item in items {
            print(item.assetURL!)
        }
        //        let player = MPMusicPlayerController.systemMusicPlayer
        //        player.setQueue(with: mediaCollection)
        //
        //        player.play()
    }
    
    func MusicInApp(){
        if arrURL.count < 4 {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let MusicView = sb.instantiateViewController(withIdentifier: "AppMusic") as! AppMusicViewController
            self.navigationController?.pushViewController(MusicView, animated: true)
        }
    }
    
    func ItunesMusic(){
        displayMediaPickerAndPlayItem()
    }
    
    func RecordAudio(){
        if arrURL.count < 4 {
            recordPermission()
            if audioRecorder == nil {
                startRecord()
                isRecord = true
            } else{
                finishRecord(success: true)
                isRecord = false
            }
        }
    }
    
    func MergeVideoAudioVC(){
//
        
    }
}

extension PBViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            MusicInApp()
        case 1:
            ItunesMusic()
        case 2:
            RecordAudio()
            collectionView2.reloadItems(at: [indexPath])
//            MergeVideoAudioVC()
            //            case 0:
            //                gotoEditVolume()
            //            case 1:
            //                gotoEditRate()
            //            case 2:
            //                gotoDeleteAudioFile()
            //            case 3:
            //                gotoSplitView()
            //            case 4:
            //                dupicateAudioFile()
            //            case 5:
        //                chooseQuality()
        default:
            print(indexPath.row)
        }
    }
}

//MARK: Extension

//CollectionView
extension PBViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonCell", for: indexPath) as? ButtonCell {
            let data = arr[indexPath.row]
            let hasAudio = arrURL.count != 0
            
            cell.updateView(hasAudio: indexPath.row < 3 || hasAudio)
            
            if isRecord && indexPath.row == 2 {
                cell.initView(title: data.title, img: "Stop")
            } else{
                cell.initView(title: data.title, img: data.image)
            }
            if indexPath.row >= 3 {
                if hasAudio {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            } else {
                cell.isUserInteractionEnabled = true
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let xWidth = collectionView.frame.width
        let xHeight = collectionView.frame.height
        return CGSize(width: xWidth / 7, height: xHeight)
    }
}

extension PBViewController: UICollectionViewDelegateFlowLayout{
    
}

//TableView
extension PBViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableView.cellForRow(at: indexPath)?.textLabel?.text ?? indexPath.row)
    }
}

extension PBViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if arrURL.count != 0 {
            if indexPath.row < arrURL.count {
                cell.textLabel?.text = arrURL[indexPath.row].absoluteString
            }
        }
        return cell
    }
}
