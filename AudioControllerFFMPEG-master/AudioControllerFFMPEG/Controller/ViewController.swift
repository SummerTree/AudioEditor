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
    var player = AVAudioPlayer()
    var volume: Float?
    var volumeRate: Float = 0.1
    var rate: Float?
    var steps: Float = 0.25
    var fileManage = HandleOutputFile()
    var path: String!
    var asset: AVAsset!
    var quality: String = "1280:720"
    var startTime: CGFloat?
    var endTime: CGFloat?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var mediaPicker: MPMediaPickerController?
    var myMusicPlayer: MPMusicPlayerController?
    var audioPlayer: AVAudioPlayer?
    
    var isPlay = false
    var isRecord = false
    var recordNum = 0
    var arrURL = [URL]()
    var recordURL:URL?
    var selectedMusic: Int!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        path = fileManage.getFilePath(name: "small", type: "mp4")
        
        initCollectionView()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        asset = AVAsset(url: URL(fileURLWithPath: path))
        
        addAudioPlayer(with: URL(fileURLWithPath: path))
        
        initTrimmerView(asset: asset)
        
        if arrURL.count > 0 {
            for i in 0..<arrURL.count{
                print(arrURL[i])
            }
        }
        if arrURL.count > 0 {
            collectionView.reloadData()
            tableView.reloadData()
        }

    }
    
    
    // MARK: Add AudioPlayer
    
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
        setMedia()
        changeIconBtnPlay()
    }
    
    func setMedia() {
        player.rate = rate! * steps
        player.volume = volumeRate * volume!
    }
    
    //MARK: Init View, Player...
    func initCollectionView() {
        collectionView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellWithReuseIdentifier: "ButtonCell")
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
    
    private func initTrimmerView(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.trimmerView.themeColor = .white
        self.trimmerView.showsRulerView = false
        self.trimmerView.maxLength = CGFloat(player.duration)
        self.trimmerView.trackerColor = .white
        self.trimmerView.thumbWidth = 10
        self.trimmerView.resetSubviews()
        setLabelTime()
 
    }
    
    //-----------
    
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
    
    func ItunesMusic(){
        if arrURL.count < 4 {
            displayMediaPickerAndPlayItem()
        }
    }
    
    
    // MARK: Navigate to another view
    
    func MusicInApp(){
        if arrURL.count < 4 {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let MusicView = sb.instantiateViewController(withIdentifier: "AppMusic") as! AppMusicViewController
            MusicView.delegate = self
            navigationController?.pushViewController(MusicView, animated: true)
        }
    }
    
    func gotoEditVolume() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VolumeView") as! VolumeViewController
        view.delegate = self
        view.volume = volume
        view.volumeRate = volumeRate
        view.rate = rate
        view.steps = steps
        view.path = arrURL[selectedMusic].path
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    func gotoEditRate() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpeedView") as! SpeedViewController
        view.delegate = self
        view.volume = volume
        view.volumeRate = volumeRate
        view.rate = rate
        view.steps = steps
        view.path = self.path
        view.path = arrURL[selectedMusic].path
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    func gotoDeleteAudioFile() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DeleteView") as! DeleteViewController
        view.volume = volume
        view.volumeRate = volumeRate
        view.rate = rate
        view.steps = steps
        view.path = self.arrURL[selectedMusic].path
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    func gotoSplitView() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SplitView") as! SplitViewController
        view.volume = volume
        view.volumeRate = volumeRate
        view.rate = rate
        view.steps = steps
        view.path = self.path
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    func chooseQuality() {
        let view = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ConfigView") as! ConfigViewController
        view.delegate = self
        view.myQuality = quality
        view.modalPresentationStyle = .overCurrentContext
        self.present(view, animated: true)
        
    }
    
    
    func dupicateAudioFile() {
        let outputURL = fileManage.createUrlInApp(name: "Duplicate.mp3")
        
        // CMD to duplicate audio file
        let cmd = "-i \(path!) -vn -ac 2 -ar 44100 -ab 320k -f mp3 \(outputURL)"
        MobileFFmpeg.execute(cmd)
        
        print(fileManage.saveToDocumentDirectory(url: outputURL))
    }
    
    
    func changeIconBtnPlay() {
        if player.isPlaying {
            btnPlay.setImage(UIImage(named: "icon_pause"), for: .normal)
        } else {
            btnPlay.setImage(UIImage(named: "icon_play"), for: .normal)
        }
    }
    
    
    
    //MARK: Handle IBAction
    @IBAction func playAudio(_ sender: Any) {
        
        if player.isPlaying {
            player.pause()
            stopPlaybackTimeChecker()
        } else {
            player.play()
            startPlaybackTimeChecker()
        }
        changeIconBtnPlay()
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
    
    
    @IBAction func saveChange(_ sender: Any) {
        
        let alert = UIAlertController(title: "Do you want to save all changes?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: ({action in
        })))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: ({action in
            
            self.player.pause()
            
            let hour = Date().toString(dateFormat: "HH:mm:ss")
            let date = Date().toString(dateFormat: "YYYY:MM:dd")
            let type = ".mp4"
            
            let output = self.fileManage.createUrlInApp(name: "\(date)_\(hour)\(type)")

            let newVolume = self.volume! * self.volumeRate
            let newSpeed = self.rate! * self.steps
            
            let str = "-y -i \(self.path!) -filter_complex \"[0:a]volume=\(newVolume),atempo=\(newSpeed)[a];[0:v]setpts=PTS*1/\(newSpeed),scale=\(self.quality)[v]\" -map \"[a]\" -map \"[v]\" -preset ultrafast \(output)"
            
            let serialQueue = DispatchQueue(label: "serialQueue")
            
            DispatchQueue.main.async {
                ZKProgressHUD.show()
            }
            
            serialQueue.async {
                MobileFFmpeg.execute(str)
                let x = (self.fileManage.saveToDocumentDirectory(url: output))
                self.fileManage.moveToLibrary(destinationURL: x)
                DispatchQueue.main.async {
                    ZKProgressHUD.dismiss()
                    ZKProgressHUD.showSuccess()
                }
                
            }
        })))
        present(alert, animated: true, completion: nil)
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
            print(recordURL!)
            tableView.reloadData()
            collectionView.reloadData()
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
    
    // MARK: Merge audio with video
    func mergeAudioWithVideo() {
        let output = fileManage.createUrlInApp(name: "output.mp4")
        let outputVideo = fileManage.createUrlInApp(name: "outputVideo.mp3")
        let outputFinal = fileManage.createUrlInApp(name: "outputFinal.mp3")
        
        guard let x = Bundle.main.path(forResource: "small", ofType: "mp4") else {
            return
        }
        
        // Get audio from mp4 file
        let extract = "-i \(x) \(outputVideo)"
        MobileFFmpeg.execute(extract)
        
        // Merge 2 audio file
        let final = "-i \(outputVideo) -i \(path!)  -filter_complex amerge -c:a libmp3lame -q:a 4 \(outputFinal)"
        MobileFFmpeg.execute(final)
        
        // Merge audio file with video
        let str = "-i \(x) -i \(outputFinal) -map 0:v -map 1:a -c copy -y \(output)"
        MobileFFmpeg.execute(str)
        
        print(fileManage.saveToDocumentDirectory(url: output))
        fileManage.moveToLibrary(destinationURL: output)
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PassVolumeBackDelegate, PassSpeedBackDelegate, ICGVideoTrimmerDelegate, PassQualityDelegate, PassAudioURLBackDelegate{
    
    
    
    
    // MARK: Rewrite func for CollectionView
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        player.currentTime = 0
        player.pause()
        
        switch indexPath.row {
        case 0:
            MusicInApp()
        case 1:
            ItunesMusic()
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
        case 8:
            chooseQuality()
        default:
            print(indexPath.row)
        }
    }
    
    // MARK: Rewrite func for TrimmerView
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        player.pause()
        changeIconBtnPlay()
        
        player.currentTime = Double(startTime)
        
        self.startTime = startTime
        self.endTime = endTime
        setLabelTime()
    }
    
    //MARK: Rewirite function for userdefine Protocol
    
    func passSpeedData(speed: Float) {
        self.rate = speed
    }
    
    func passVolumeBack(volume: Float) {
        self.volume = volume
    }
    
    func getQuality(quality: String) {
        self.quality = quality
    }
    
    func passAudioURLBack(path: String) {

        self.arrURL.append(URL(fileURLWithPath: path))
    }
}


//MARK: TableView
extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if arrURL.count != 0 {
            if indexPath.row < arrURL.count {
                cell.textLabel?.text = arrURL[indexPath.row].absoluteString
                selectedMusic = indexPath.row
            }
        }
        return cell
    }
}
