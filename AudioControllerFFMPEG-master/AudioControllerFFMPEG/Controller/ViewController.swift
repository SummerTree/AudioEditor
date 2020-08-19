//
//  ViewController.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/13/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import AVFoundation
import ICGVideoTrimmer
import ZKProgressHUD
import Photos
import MediaPlayer

class ViewController: UIViewController, AVAudioRecorderDelegate, MPMediaPickerControllerDelegate {
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var formView: UIView!
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    @IBOutlet weak var tableView: UITableView!
    
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var arr = [ModelItem]()
    var Audios = [ArrAudio]()
    var volume: Float?
    var volumeRate: Float = 0.01
    var rate: Float?
    var steps: Float = 0.25
    var fileManage = HandleOutputFile()
    var asset: AVAsset!
    var quality: String = "1280:720"
    var startTime: CGFloat?
    var endTime: CGFloat?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var urlVideo: URL!
    var mediaPicker: MPMediaPickerController?
    var myMusicPlayer: MPMusicPlayerController?
    var audioPlayer: AVAudioPlayer?
    var videoPlayer: AVPlayer!
    var isPlay = false
    var isRecord = false
    var recordNum = 0
    var arrURL = [URL]()
    var recordURL:URL?
    var position: Int!
    var hasChooseMusic = false
    var hasChangeMedia: Bool = false
    var isVideo: Bool!
    var delayTime: CGFloat!
    var isReload: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isReload = false
        
        urlVideo = URL(fileURLWithPath: fileManage.getFilePath(name: "small", type: "mp4"))
        
        asset = AVAsset(url: urlVideo)
        addVieoPlayer(asset: asset, playerView: playerView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        createAudioSession()
        initCollectionView()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        trimmerView.addGestureRecognizer(tap)
    }
    
    @objc func doubleTapped() {
        pauseMedia()
        isVideo = true
        gotoEditVolume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if arrURL.count > 0 {
            tableView.reloadData()
            collectionView.reloadData()
        }
        initTrimmerView(asset: asset)
        position = -1
        hasChooseMusic = false
        isVideo = false
    }
    
    // create session
    func createAudioSession(){
        do {
            /// this codes for making this app ready to takeover the device nlPlayer
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,mode:.moviePlayback ,options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    // MARK: Add AudioPlayer
    
    private func getAudios() {
        let numURL = arrURL.count
        let numAudio = Audios.count
        if numURL > 0 {
            for i in 0..<numURL {
                do {
                    let audio = try AVAudioPlayer(contentsOf: arrURL[i])
                    audio.enableRate = true
                    if i <= (numAudio - 1) {
                        audio.rate = Audios[i].player.rate
                        audio.volume = Audios[i].player.volume
                        Audios[i].player = audio
                    } else {
                        audio.rate = self.rate! * steps
                        audio.volume = self.volume! * volumeRate
                        Audios.append(ArrAudio(player: audio, delayTime: delayTime))
                    }
                } catch {
                    
                }
            }
        }
    }
    
    private func addVieoPlayer(asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: videoPlayer)
        layer.backgroundColor = UIColor.black.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        //        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.addSublayer(layer)
        endTime = CGFloat(CMTimeGetSeconds((videoPlayer.currentItem?.asset.duration)!))
        startTime = 0
        delayTime = startTime
        videoPlayer.volume = 0.6
        initMedia()
    }
    
    private func addAudioPlayer() {
        getAudios()
        initMedia() 
    }
    
    // Nếu điểm bắt đầu của trimmer view chưa tới thời gian delay mà music được thêm vào
    // -> trình phát nhạc quản lí music của nó vẫn như cũ
    
    func isOverTimeDelay(startTime: CGFloat, delayTime: CGFloat) -> Bool {
        return startTime > delayTime
    }
    
    func setTimeMusic(audio: ArrAudio, startTime: CGFloat, play: Bool) {
        var time: CGFloat = 0
        if isOverTimeDelay(startTime: startTime, delayTime: audio.delayTime) {
            time = startTime - audio.delayTime
        }
        audio.player.currentTime = Double(time)
        if !play {
            audio.player.pause()
        }
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let start = self.startTime {
            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(start), preferredTimescale: 600))
            videoPlayer.pause()
            if hasChooseMusic {
                setTimeMusic(audio: Audios[position], startTime: start, play: false)
            } else {
                for audio in Audios {
                    setTimeMusic(audio: audio, startTime: start, play: false)
                }
            }
        }
        changeIconBtnPlay()
    }
    
    // MARK: Playback time checker
    
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
        
    }
    
    func stopPlaybackTimeChecker(){
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        
        guard let start = startTime, let endTime = endTime, let videoPlayer = videoPlayer else {
            return
        }
        
        let playBackTime = CGFloat(CMTimeGetSeconds(videoPlayer.currentTime()))
        trimmerView.seek(toTime: playBackTime)
        
        
        if playBackTime >= endTime {
            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(start), preferredTimescale: 600), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            videoPlayer.pause()
                      
            if hasChooseMusic {
                setTimeMusic(audio: Audios[position], startTime: start, play: false)
            } else {
                for audio in Audios {
                    setTimeMusic(audio: audio, startTime: start, play: false)
                }
            }
            
            trimmerView.seek(toTime: start)
            changeIconBtnPlay()
        } else {
//            delayTime = playBackTime
            if hasChooseMusic {
                if !Audios[position].player.isPlaying {
                    setTimeMusic(audio: Audios[position], startTime: playBackTime, play: true)
                    if isOverTimeDelay(startTime: playBackTime, delayTime: Audios[position].delayTime){
                        if videoPlayer.isPlaying {
                            Audios[position].player.play()
                        }
                    }
                }
            } else {
                for audio in Audios {
                    if !audio.player.isPlaying {
                        setTimeMusic(audio: audio, startTime: playBackTime, play: true)
                        if isOverTimeDelay(startTime: playBackTime, delayTime: audio.delayTime){
                            if videoPlayer.isPlaying {
                                audio.player.play()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setLabelTime() {
        lblStartTime.text = CMTimeMakeWithSeconds(Float64(startTime!), preferredTimescale: 600).positionalTime
        lblEndTime.text = CMTimeMakeWithSeconds(Float64(endTime!), preferredTimescale: 600).positionalTime
        lblDuration.text = CMTimeMakeWithSeconds(Float64(endTime! - startTime!), preferredTimescale: 600).positionalTime
    }
    
    func initMedia() {
        if volume == nil {
            volume = 60.0
        }
        if rate == nil {
            rate = 4.0
        }
        
        if hasChangeMedia {
            setMedia()
        } else {
            for audio in Audios {
                audio.player.rate = 4 * steps
                audio.player.volume = 60 * volumeRate
            }
        }
        changeIconBtnPlay()
    }
    
    func setMedia() {
        if position >= 0 {
            Audios[position].player.volume = volume! * volumeRate
            Audios[position].player.rate = rate! * steps
        }
    }
    
    //MARK: Init View, Player...
    func initCollectionView() {
        collectionView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellWithReuseIdentifier: "ButtonCell")
        arr.append(ModelItem(title: "MUSIC", image: "Music"))
        arr.append(ModelItem(title: "ITUNES", image: "Itunes"))
        arr.append(ModelItem(title: "RECORD", image: "Record"))
        arr.append(ModelItem(title: "VOLUME", image: "icon_sound"))
        arr.append(ModelItem(title: "SPEED", image: "icon_speed"))
        arr.append(ModelItem(title: "DELETE", image: "icon_trash"))
        arr.append(ModelItem(title: "SPLIT", image: "icon_split"))
        arr.append(ModelItem(title: "DUPLICATE", image: "icon_duplicate"))
    }
    
    //MARK: Init TrimmerView
    
    private func initTrimmerView(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.trimmerView.themeColor = .white
        self.trimmerView.showsRulerView = false
        self.trimmerView.maxLength = CGFloat(CMTimeGetSeconds((videoPlayer.currentItem?.asset.duration)!))
        self.trimmerView.trackerColor = .white
        self.trimmerView.thumbWidth = 12
        self.trimmerView.resetSubviews()
        setLabelTime()
    }
    
    // MARK: Display media picker
    
    func displayMediaPickerAndPlayItem(){
        mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        
        if let picker = mediaPicker{
            //            print("Successfully instantiated a media picker")
            picker.delegate = self
            view.addSubview(picker.view)
            present(picker, animated: true, completion: nil)
            //            playItunesItem()
        } else {
            print("Could not instantiate a media picker")
        }
    }
    
    func ItunesMusic(){
        if arrURL.count < 4 {
            displayMediaPickerAndPlayItem()
        }
    }
    
    // MARK: Navigate to another view
    
    func MusicInApp(){
        self.delayTime = CGFloat(videoPlayer.currentTime().seconds)
        if arrURL.count < 4 {
            let MusicView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AppMusic") as! AppMusicViewController
            MusicView.delegate = self
            MusicView.delayTime = self.delayTime
            MusicView.modalPresentationStyle = .overCurrentContext
            self.present(MusicView, animated: true)
        }
    }
    
    func gotoEditVolume() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VolumeView") as! VolumeViewController
        view.delegate = self
        view.volumeRate = volumeRate
        view.steps = steps
        view.isVideo = isVideo
        if isVideo {
            view.url = urlVideo
            view.volume = videoPlayer.volume / volumeRate
        } else {
            view.url = arrURL[position]
            view.volume = Audios[position].player.volume / volumeRate
            view.rate = Audios[position].player.rate / steps
        }
        view.modalPresentationStyle = .overCurrentContext
        self.present(view, animated: true)
    }
    
    func gotoEditRate() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpeedView") as! SpeedViewController
        view.delegate = self
        view.volume = Audios[position].player.volume / volumeRate
        view.rate = Audios[position].player.rate / steps
        view.volumeRate = volumeRate
        view.steps = steps
        view.url = arrURL[position]
        view.modalPresentationStyle = .overCurrentContext
        self.present(view, animated: true)
    }
    
    func gotoDeleteAudioFile() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DeleteView") as! DeleteViewController
        view.volume = Audios[position].player.volume / volumeRate
        view.rate = Audios[position].player.rate / steps
        view.volumeRate = volumeRate
        view.steps = steps
        view.url = self.arrURL[position]
        view.delegate = self
        view.modalPresentationStyle = .overCurrentContext
        self.present(view, animated: true)
    }
    
    func gotoSplitView() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SplitView") as! SplitViewController
        view.volume = Audios[position].player.volume / volumeRate
        view.rate = Audios[position].player.rate / steps
        view.volumeRate = volumeRate
        view.steps = steps
        view.url = self.arrURL[position]
        view.delegate = self
        view.modalPresentationStyle = .overCurrentContext
        self.present(view, animated: true)
    }
    
    //MARK: Itunes
        
    func gotoItunesView(){
        
        if arrURL.count < 4 {
            let picker = MPMediaPickerController(mediaTypes: .anyAudio)
            picker.delegate = self
            picker.allowsPickingMultipleItems = false
            present(picker, animated: true, completion: nil)
        }
    }
        
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        guard let mediaItem = mediaItemCollection.items.first else {
            print("No song selected")
            return
        }
        if mediaItem.hasProtectedAsset {
            print("Must be played only via MPMusicPlayer")
        } else {
            print("Can be played both via AVPlayer & MPMusicPlayer")
        }
        let audioUrl = mediaItem.assetURL
        print("Audio URL:::")
        print(audioUrl ?? "No file detected")
        arrURL.append(audioUrl!)
        tableView.reloadData()
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Duplicate
    func dupicateAudioFile() {
        
        let outputTemp = fileManage.createUrlInApp(name: "temp.mp3")
        let outputDuplicate = fileManage.createUrlInApp(name: "Duplicate.mp3")
        let cmd = "-i \(arrURL[position]) -vn -ac 2 -ar 44100 -ab 320k -f mp3 \(outputTemp)"
        let cmd2 = "-i \"concat:\(outputTemp)|\(outputTemp)\" -c copy \(outputDuplicate)"
        
        let serialQueue = DispatchQueue(label: "serialQueue")
        
        DispatchQueue.main.async {
            ZKProgressHUD.show()
        }
        
        serialQueue.async {
            MobileFFmpeg.execute(cmd)
            MobileFFmpeg.execute(cmd2)
            let dupURL = self.fileManage.saveToDocumentDirectory(url: outputDuplicate)
            let audio = self.Audios[self.position]
            self.arrURL[self.position] = dupURL
            self.volume = audio.player.volume / self.volumeRate
            self.rate = audio.player.rate / self.steps
            DispatchQueue.main.async {
                self.tableView.reloadData()
                ZKProgressHUD.dismiss()
                ZKProgressHUD.showSuccess()
            }
        }
    }
    
    func changeIconBtnPlay() {
        if videoPlayer.isPlaying {
            btnPlay.setImage(UIImage(named: "icon_pause"), for: .normal)
        } else {
            btnPlay.setImage(UIImage(named: "icon_play"), for: .normal)
        }
    }
    
    //MARK: Handle IBAction
    @IBAction func playAudio(_ sender: Any) {
        
        if videoPlayer.isPlaying {
            pauseMedia()
            stopPlaybackTimeChecker()
        } else {
            playMedia()
            startPlaybackTimeChecker()
        }
        changeIconBtnPlay()
    }
    
    func pauseMedia() {
        if hasChooseMusic {
            if Audios[position].player.isPlaying && videoPlayer.isPlaying {
                Audios[position].player.pause()
            }
        } else {
            for audio in Audios {
                if audio.player.isPlaying && videoPlayer.isPlaying {
                    audio.player.pause()
                }
            }
        }
        videoPlayer.pause()
    }
    
    func playMedia() {
        if hasChooseMusic {
            if (!videoPlayer.isPlaying) && (videoPlayer.currentTime().seconds >= Double(Audios[position].delayTime)) {
                Audios[position].player.play()
            }
        } else {
            for audio in Audios {
                if (!videoPlayer.isPlaying) && (videoPlayer.currentTime().seconds >= Double(audio.delayTime)) {
                    audio.player.play()
                }
            }
        }
        videoPlayer.play()
    }
    
    @IBAction func saveChange(_ sender: Any) {
        pauseMedia()
        ZKProgressHUD.show()
        let queue = DispatchQueue(label: "saveQueue")
        queue.async {
            print(self.mergeAudioWithVideo())
            DispatchQueue.main.async {
                ZKProgressHUD.dismiss()
                ZKProgressHUD.showSuccess()
            }
        }
        
    }
    
    @IBAction func back(_ sender: Any) {
    }
    
    
    //MARK: Record audio file
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
            }
        } catch {
            // failed to record!
            print("Permission fail")
        }
    }
    
    func RecordAudio() {
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
    
    func startRecord(){
        let fileName = "recordFile\(recordNum + 1).m4a"
        recordNum += 1
        recordURL = fileManage.getDocumentsDirectory().appendingPathComponent(fileName)
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
            tableView.reloadData()
            collectionView.reloadData()
        } else{
            print("Record failed")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecord(success: false)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error!.localizedDescription)")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error!.localizedDescription)")
    }
    
    // MARK: Merge audio with video
    func mergeAudioWithVideo() -> URL {
        let output = fileManage.createUrlInApp(name: "output.mp4")
        let outputVideo = fileManage.createUrlInApp(name: "outputVideo.mp3")
        let outputMerge = fileManage.createUrlInApp(name: "outputMerge.mp3")
        let path = urlVideo.path
        
        // Get audio from mp4 file
        let extract = "-i \(path) -af \"volume=\(videoPlayer.volume)\" \(outputVideo)"
        MobileFFmpeg.execute(extract)
        
        var isEmpty: Bool
        var outputAudio: URL
        
        (outputAudio, isEmpty) = mergeAllOfAudioURL()
        
        // Merge audio file
        
        if isEmpty {
            fileManage.clearTempDirectory()
            return urlVideo
        } else {
            let final = "-i \(outputVideo) -i \(outputAudio) -filter_complex amerge -c:a libmp3lame -q:a 4 \(outputMerge)"

            MobileFFmpeg.execute(final)

            // Merge audio file with video

            let str2 = "-i \(path) -i \(outputMerge) -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 \(output)"
            MobileFFmpeg.execute(str2)

            // Move to directory
            let urlDir = fileManage.saveToDocumentDirectory(url: output)
            fileManage.clearTempDirectory()
            return urlDir
        }
    }
    
    func mergeAllOfAudioURL() -> (URL, Bool) {
        var url = [URL]()
        let urlNum = arrURL.count
        let outputAudio = fileManage.createUrlInApp(name: "OutputAudio.mp3")
        if arrURL.count > 0 {
            for i in 0 ..< urlNum {
                let output = fileManage.createUrlInApp(name: "\(i).mp3")
                let audio = "-i \(arrURL[i]) -af \"volume=\(Audios[i].player.volume), atempo=\(Audios[i].player.rate)\" \(output)"
                MobileFFmpeg.execute(audio)
                url.append(output)
            }
        }
        
        let urlConvert = url.count
        if urlConvert > 0 {
            var str = ""
            switch urlConvert {
            case 1:
                let delay0 = Audios[0].delayTime * 1000
                str = "-i \(url[0]) -af adelay=\(delay0) -c:a libmp3lame \(outputAudio)"
            case 2:
                let delay0 = Audios[0].delayTime * 1000
                let delay1 = Audios[1].delayTime * 1000
                str = "-i \(url[0]) -i \(url[1]) -filter_complex \"[0]adelay=\(delay0)|\(delay0)[b];[1]adelay=\(delay1)|\(delay1)[c];[b][c]amerge[a]\" -map \"[a]\" -c:a libmp3lame -q:a 4 \(outputAudio)"
            case 3:
                let delay0 = Audios[0].delayTime * 1000
                let delay1 = Audios[1].delayTime * 1000
                let delay2 = Audios[2].delayTime * 1000
                str = "-i \(url[0]) -i \(url[1]) -i \(url[2]) -filter_complex \"[0]adelay=\(delay0)|\(delay0)[b];[1]adelay=\(delay1)|\(delay1)[c];[2]adelay=\(delay2)|\(delay2)[d];[b][c][d]amerge[a]\" -map \"[a]\" -c:a libmp3lame -q:a 4 \(outputAudio)"
            case 4:
                let delay0 = Audios[0].delayTime * 1000
                let delay1 = Audios[1].delayTime * 1000
                let delay2 = Audios[2].delayTime * 1000
                let delay3 = Audios[3].delayTime * 1000
                str = "-i \(url[0]) -i \(url[1]) -i \(url[2]) -i \(url[3]) -filter_complex \"[0]adelay=\(delay0)|\(delay0)[b];[1]adelay=\(delay1)|\(delay1)[c];[2]adelay=\(delay2)|\(delay2)[d];[3]adelay=\(delay3)|\(delay3)[e];[b][c][d][e]amerge[a]\" -map \"[a]\" -c:a libmp3lame -q:a 4 \(outputAudio)"
            default:
                print("Default")
            }
            MobileFFmpeg.execute(str)
            return (outputAudio, false)
        }
        else {
            return (outputAudio, true)
        }
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ICGVideoTrimmerDelegate, TransformDataDelegate {
    
    // MARK: Rewrite func for CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonCell", for: indexPath) as? ButtonCell {
            let data = arr[indexPath.row]
            let hasAudio = arrURL.count != 0 && position != -1
            
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        hasChangeMedia = true
        
        for audio in Audios {
            audio.player.currentTime = 0
            audio.player.pause()
        }
        
        videoPlayer.seek(to: CMTime.zero)
        videoPlayer.pause()
        changeIconBtnPlay()
        
        switch indexPath.row {
        case 0:
            MusicInApp()
        case 1:
            gotoItunesView()
        case 2:
            RecordAudio()
            collectionView.reloadItems(at: [indexPath])
        case 3:
            gotoEditVolume()
        case 4:
            gotoEditRate()
        case 5:
            gotoDeleteAudioFile()
        case 6:
            gotoSplitView()
        case 7:
            dupicateAudioFile()
        default:
            print(indexPath.row)
        }
    }
    
    // MARK: Rewrite func for TrimmerView
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        
        for audio in Audios {
            // Nếu trimmer chưa kéo tới thời gian add audio vào thì sẽ không thay đổi thời gian bắt đầu của audio đó
            if startTime <= audio.delayTime {
                audio.player.currentTime = Double(audio.delayTime)
            } else {
                audio.player.currentTime = Double(startTime)
            }
            audio.player.pause()
        }
        
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(startTime), preferredTimescale: 600), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        videoPlayer.pause()
        changeIconBtnPlay()
        
        trimmerView.seek(toTime: startTime)
//        delayTime = startTime
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
    
    //MARK: Rewirite function for userdefine Protocol
    
    func transform(url: URL, volume: Float, rate: Float) {
        if isVideo {
            videoPlayer.volume = volume
        } else {
            self.arrURL[position] = url
            self.Audios[position].player.volume = volume
            self.Audios[position].player.rate = rate
            self.volume = volume / volumeRate
            self.rate = rate / steps
        }
        isReload = true
        viewDidAppear(true)
    }
    
    func transformQuality(quality: String) {
        self.quality = quality
    }
    
    func transformSplitMusic(url: URL) {
        self.arrURL[position] = url
        isReload = true
        viewDidAppear(true)
    }
    
    func isRemove(isRemove: Bool) {
        if arrURL.count > 0 {
            if isRemove {
                arrURL.remove(at: position)
                Audios.remove(at: position)
            }
            tableView.reloadData()
            collectionView.reloadData()
        }
        position = -1
        hasChooseMusic = false
    }
    
    func isGetMusic(state: Bool) {
        if state {
            tableView.reloadData()
        }
    }
    
    func transformMusicPath(path: String) {
        if(arrURL.count < 4) {
            self.arrURL.append(URL(fileURLWithPath: path))
        } else {
            print("Number of audio file more than 4")
        }
    }
    
    func delayTime(delayTime: CGFloat) {
        self.delayTime = delayTime
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Rewrite func for TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrURL.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if arrURL.count != 0 {
            if indexPath.row < arrURL.count {
                cell.textLabel?.text = arrURL[indexPath.row].lastPathComponent
                addAudioPlayer()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if arrURL.count > 0 {
            
            // Pause all Audio and video
            for audio in Audios {
                audio.player.pause()
            }
            videoPlayer.pause()
            
            if indexPath.row != position {
                position = indexPath.row
                hasChooseMusic = true
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
                position = -1
                hasChooseMusic = false
            }
            collectionView.reloadData()
            changeIconBtnPlay()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            arrURL.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
