//
//  MusicPlayerViewController.swift
//  MEAR
//
//  Created by okura on 2018/10/28.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit
import MediaPlayer

class MusicPlayerViewController: UIViewController {

    var indexId: Int = 0
    var currentSongList: Array<SongItem> = []
    
    @IBOutlet weak var songImageView: UIImageView!
    
    @IBOutlet weak var songLabel: UILabel!
    
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var remaindTimeLabel: UILabel!

    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var songTimeSlider: UISlider!
    
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBOutlet weak var volumeSliderView: UIView!
    
    var timer = Timer()
    
    private let musicDataController = MusicDataController.shared
    private let musicController = MPMusicController.shared
    
    private var songChanged: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewUpdate(songItem: currentSongList[indexId])
        
        self.musicController.stop()
        self.musicController.setPlayer(list: self.currentSongList, id: indexId)
        self.musicController.play()
        
        
        let mpVolumeView = MPVolumeView(frame: self.volumeSliderView.bounds)
        self.volumeSliderView.addSubview(mpVolumeView)
        
        self.songTimeSlider.value = 0.0
//        self.songTimeSlider.isHidden = true
        
        
        self.playButton.setImage(UIImage(named: "icon-pause"), for: .normal)
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                     selector: #selector(updateslider), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextMusic(_ sender: UIButton) {
        indexId = indexId + 1
        self.musicController.setPlayer(list: self.currentSongList, id: indexId)
        self.musicController.next()
        self.viewUpdate(songItem: self.currentSongList[indexId])
    }
    
    @IBAction func prevMusic(_ sender: UIButton) {
        self.musicController.prev()
    }
    
    @IBAction func stopMusic(_ sender: Any) {
        if(self.musicController.currentStatus == MusicController.PlayerStatus.PAUSE) {
            self.musicController.play()
            self.playButton.setImage(UIImage(named: "icon-pause"), for: .normal)
        } else if(self.musicController.currentStatus == MusicController.PlayerStatus.PLAY) {
            self.musicController.pause()
            self.playButton.setImage(UIImage(named: "icon-play"), for: .normal)
        }
    }
    
    func viewUpdate(songItem: SongItem) {
        if songItem.artwork?.image != nil {
            self.songImageView?.contentMode = UIViewContentMode.scaleAspectFit
            self.songImageView?.image = songItem.artwork?.image(at: CGSize(width:240, height:240))
        }
        
        self.songLabel.text = songItem.title
        self.artistLabel.text = songItem.artist
        self.currentTimeLabel.text = songItem.duration
        self.remaindTimeLabel.text = songItem.duration
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changeVolume(_ sender: UISlider) {
//        self.musicDataControimport MediaPlayerlle
    }
    
    //スライダーの位置を曲の再生位置と同期する
    @objc func updateslider(){
//        self.songTimeSlider.setValue(Float(self.musicController.), animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
