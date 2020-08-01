//
//  ButtonCell.swift
//  AudioControllerFFMPEG
//
//  Created by Viet Hoang on 7/14/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit

class ButtonCell: UICollectionViewCell {
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var txtTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func initView(title: String, img: String) {
        txtTitle.text = title
        imgIcon.image = UIImage(named: img)
    }
    
    func updateView(hasAudio:Bool) {
        txtTitle.alpha = hasAudio ? 1 : 0.5
        imgIcon.alpha = hasAudio ? 1 : 0.5
    }
}
