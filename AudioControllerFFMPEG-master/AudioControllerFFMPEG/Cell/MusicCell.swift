//
//  MusicCell.swift
//  AudioControllerFFMPEG
//
//  Created by Apple on 8/12/20.
//  Copyright © 2020 Viet Hoang. All rights reserved.
//

import UIKit

protocol MusicCellDelegate: class {
    func clickedBtnUse(index: Int)
}

class MusicCell: UITableViewCell {

    @IBOutlet var imgIcon: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var btnUse: UIButton!
    
    weak var delegate: MusicCellDelegate?
    
    static let identifier = "MusicCell"
    
    var index: Int!
    
    func configure(with title: String, image: String, index: Int, isHiddenBtn: Bool){
        self.index = index
        lblTitle.text = title
        imgIcon.image = UIImage(named: image)
        btnUse.isHidden = isHiddenBtn
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func BtnTapped(_ sender: Any) {
        delegate?.clickedBtnUse(index: index)
    }
    
}
