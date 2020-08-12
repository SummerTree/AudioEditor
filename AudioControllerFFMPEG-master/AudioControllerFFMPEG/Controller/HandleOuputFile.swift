//
//  HandleOuputFile.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/22/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import Photos
import AVKit

class HandleOutputFile {
    
    func createUrlInApp(name: String ) -> URL {
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(name)")
        removeFileIfExists(fileURL: url)
        return url
    }
    
    
    func saveToDocumentDirectory(url: URL) -> URL {
        
        // Create document folder url
        let documenDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create destination file url
        let destinationURL = documenDirectoryURL.appendingPathComponent(url.lastPathComponent)
        
        removeFileIfExists(fileURL: destinationURL)
        
        do {
            try FileManager.default.moveItem(at: url, to: destinationURL)
            print("File moved to document folder")
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return destinationURL
    }
    
    func moveToLibrary(destinationURL: URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(destinationURL.path, nil, nil, nil)
        print("File moved to library")
    }
    
    func removeFileIfExists(fileURL: URL) {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(atPath: fileURL.path)
        }
    }
    
    // Get file path
    func getFilePath(name: String, type: String) -> String {
        guard let file = Bundle.main.path(forResource: name, ofType: type) else {
            debugPrint("Couln't open file")
            return ""
        }
        return file
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    	
    // Remove all temp file
    
    func clearTempDirectory() {
        do {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach({ file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            })
            print("Removed temp file")
        } catch {
            print(error)
        }
    }

}
