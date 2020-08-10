//
//  SongQuery.swift
//  AudioControllerFFMPEG
//
//  Created by Apple on 8/10/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit
import Foundation
import MediaPlayer

enum AudioType: Int {
    case songs = 1, albums, artists, playlists, composers
}

struct SongInfo {
    var albumTitle: String
    var artistName: String
    var songTitle:  String    
    var songId:  NSNumber
    var duration: String
}

struct CategoryInfo {
    var categoryTitle: String
    var albums: [AlbumInfo]
}

struct AlbumInfo {
    var albumTitle: String
    var songs: [SongInfo]
}

func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

class SongQuery {
    
    func getCategory() -> [CategoryInfo]{
        return [
            CategoryInfo(categoryTitle: "Songs", albums: get("Songs")),
            CategoryInfo(categoryTitle: "Albums", albums: get("Albums")),
            CategoryInfo(categoryTitle: "Artists", albums: get("Artists")),
            CategoryInfo(categoryTitle: "Playlists", albums: get("Playlists")),
            CategoryInfo(categoryTitle: "Composers", albums: get("Composers"))
        ]
    }
    
    func get(_ songCategory: String) -> [AlbumInfo] {
        var albums: [AlbumInfo] = []
        let albumsQuery: MPMediaQuery
        if songCategory == "Artists" {
            albumsQuery = MPMediaQuery.artists()
        } else if songCategory == "Albums" {
            albumsQuery = MPMediaQuery.albums()
        } else if songCategory == "Playlists" {
            albumsQuery = MPMediaQuery.playlists()
        } else if songCategory == "Songs" {
            albumsQuery = MPMediaQuery.songs()
            let albumInfo = getAlbumInfo(albumItems: albumsQuery.items!, category: "Songs")
            return [albumInfo]
        } else {
            albumsQuery = MPMediaQuery.composers()
        }
        
        let albumItems: [MPMediaItemCollection] = albumsQuery.collections! as [MPMediaItemCollection]
        for album in albumItems {
            let albumItems: [MPMediaItem] = album.items as [MPMediaItem]
            
            var albumTitle = ""
            if songCategory == "Playlists" {
                albumTitle = album.value( forProperty: MPMediaPlaylistPropertyName) as! String
            } else if songCategory == "Songs" {
                albumTitle = "Songs"
            }
            let albumInfo = getAlbumInfo(albumItems: albumItems, category: songCategory, title: albumTitle)
            albums.append(albumInfo)
        }
        
        return albums
    }
    
    func getAlbumInfo(albumItems: [MPMediaItem], category: String, title: String = "") -> AlbumInfo {
        var songs: [SongInfo] = []
        var albumTitle: String = ""
        if category == "Playlists" {
            albumTitle = title
        } else if category == "Songs" {
            albumTitle = title
        }
        for song in albumItems {
            if category == "Artists" {
                albumTitle = song.value( forProperty: MPMediaItemPropertyArtist) as! String
            } else if category == "Albums" {
                albumTitle = song.value( forProperty: MPMediaItemPropertyTitle) as! String
            } else if category == "Composers" {
                albumTitle = song.value( forProperty: MPMediaItemPropertyComposer) as! String
            }
            
            let durationValue = Int(song.playbackDuration)
            var durationStr = ""
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: durationValue)
            if (h > 0) {
                durationStr = String(format:"%02d:%02d:%02d", h, m, s)
            } else {
                durationStr = String(format:"%02d:%02d", m, s)
            }
            
            var albumTitle = ""
            var artistName = ""
            var songTitle = ""
            var songId:NSNumber = 0
            
            if let albumtitle = song.value( forProperty: MPMediaItemPropertyAlbumTitle ) as? String {
                albumTitle = albumtitle
            }
            if let artistname = song.value( forProperty: MPMediaItemPropertyArtist ) as? String {
                artistName = artistname
            }
            if let songtitle = song.value( forProperty: MPMediaItemPropertyTitle ) as? String {
                songTitle = songtitle
            }
            if let songid = song.value( forProperty: MPMediaItemPropertyPersistentID ) as? NSNumber {
                songId = songid
            }
            
            let songInfo: SongInfo = SongInfo(
                albumTitle: albumTitle,
                artistName: artistName,
                songTitle:  songTitle,
                songId:     songId,
                duration: durationStr
            )
            songs.append( songInfo )
        }
        
        let albumInfo = AlbumInfo(
            albumTitle: albumTitle,
            songs: songs
        )
        
        return albumInfo
    }
    
    func get() -> Int {
        let query = MPMediaQuery.songs()
        var mediaCollection : MPMediaItemCollection {
            return MPMediaItemCollection(items: query.items!)
        }
        return mediaCollection.count
    }
    
    static func getItem( songId: NSNumber) -> MPMediaItem {
        let property: MPMediaPropertyPredicate = MPMediaPropertyPredicate( value: songId, forProperty: MPMediaItemPropertyPersistentID)
        
        let query: MPMediaQuery = MPMediaQuery()
        query.addFilterPredicate( property)
        
        let items: [MPMediaItem] = query.items! as [MPMediaItem]
        if items.count > 0 {
            return items[0]
        } else {
            return MPMediaItem()
        }
    }
}
