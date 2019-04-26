//
//  PlaylistTableViewCell.swift
//  MEAR
//
//  Created by okura on 2018/10/13.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistImageView: UIImageView!
    
    @IBOutlet weak var playlistLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
