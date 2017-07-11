//
//  ToneNoteCell.swift
//  Tone
//
//  Created by Hisen on 2017/7/7.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import UIKit

class ToneNoteCell: UITableViewCell {
    
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func config(with toneNote: ToneNote, playFlag: Bool) {
        playBtn.layer.shadowColor = UIColor(red: 28 / 255, green: 33 / 255, blue: 45 / 255, alpha: 1.0).cgColor
        playBtn.layer.shadowRadius = 5
        playBtn.layer.shadowOpacity = 0.1
        playBtn.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        titleLabel.text = toneNote.title
        durationLabel.text = "\(toneNote.duration)\""
        if playFlag {
            playBtn.setImage(UIImage(named: "stop-black-icon.png"), for: .normal)
        } else {
            playBtn.setImage(UIImage(named: "play-black-icon.png"), for: .normal)
        }
    }
    
    func changeState(toPlay isPlay:Bool) {
        if isPlay {
            playBtn.setImage(UIImage(named: "stop-black-icon.png"), for: .normal)
        } else {
            playBtn.setImage(UIImage(named: "play-black-icon.png"), for: .normal)
        }
    }

}
