//
//  AppMusicViewController.swift
//  FFmpegExample
//
//  Created by Apple on 7/15/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import AVFoundation

class AppMusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MusicCellDelegate {
    
    @IBOutlet weak var screen: UIView!
    @IBOutlet weak var table: UITableView!
    var songs = [Song]()
    var audioPlayer: AVAudioPlayer?
    var sound:URL?
    var position = -1
    var delegate: TransformDataDelegate!
    var delayTime: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSong()
        createAudioSession()
        table.delegate = self
        table.dataSource = self
        table.register(MusicCell.nib(), forCellReuseIdentifier: MusicCell.identifier)
        addScreenTap(screen: self.screen)
    }
    
    func addScreenTap(screen: UIView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        tap.numberOfTapsRequired = 1
        screen.addGestureRecognizer(tap)
    }
    
    @objc func screenTapped(){
        audioPlayer?.stop()
        self.dismiss(animated: true)
    }
    
    func createAudioSession(){
        do {
            /// this codes for making this app ready to takeover the device nlPlayer
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,mode:.moviePlayback ,options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
             //print("error: \(error.localizedDescription)")
         }
    }
    
    func clickedBtnUse(index: Int) {
        if index != -1 {
            self.delegate.transformMusicPath(path: sound!.path)
            self.delegate.delayTime(delayTime: self.delayTime!)
            self.delegate.isGetMusic(state: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MusicCell.identifier, for: indexPath) as! MusicCell
        let song = songs[indexPath.row]
        
        cell.configure(with: song.trackName, image: song.image, index: indexPath.row, isHiddenBtn: indexPath.row != position)
        cell.delegate = self
        //configure
        if indexPath.row == position {
            cell.textLabel?.textColor = UIColor.red
        } else{
            cell.textLabel?.textColor = UIColor.black
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //songs
        playBackgroundMusic(songName: songs[indexPath.row].trackName)
        
        if indexPath.row == position {
            position = -1
            audioPlayer?.stop()
        } else {
            position = indexPath.row
        }
        table.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
    }
    
    func playBackgroundMusic(songName:String) {
        let aSound = getFileURL(song: songName)
        sound = aSound
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: aSound as URL)
            audioPlayer!.numberOfLoops = -1
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
        } catch {
            print("Cannot play the file")
        }
    }
    
    func getFileURL(song:String) -> URL  {
        let aSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: song, ofType: "mp3")!)
        return aSound as URL
    }
    
    func configureSong(){
        songs.append(Song(name: "BanhTroiNuoc", albumName: "Music", trackName: "BanhTroiNuoc", image: "SongList", artist: "HoangThuyLinh"))
        songs.append(Song(name: "BuaYeu", albumName: "Music", trackName: "BuaYeu", image: "SongList", artist: "BichPhuong"))
        songs.append(Song(name: "MotCuLua", albumName: "Music", trackName: "MotCuLua", image: "SongList", artist: "BichPhuong"))
        songs.append(Song(name: "Roi", albumName: "Music", trackName: "RoiRemix", image: "SongList", artist: "HoangThuyLinh"))
        
    }
}
