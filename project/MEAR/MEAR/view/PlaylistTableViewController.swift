//
//  PlaylistTableViewController.swift
//  MEAR
//
//  Created by okura on 2018/10/13.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit

class PlaylistTableViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var segmentedView: UIView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private let musicDataController = MusicDataController.shared
    private let musicController: MusicController = AVMusicController.shared
    
    private var playlists: Array<PlaylistItem> = [];

    // 遷移先のViewControllerに渡す変数
    var giveId:Int = 0
    var playlistTitle : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentedView.addBorder(toSide: UIView.ViewSide.Bottom, withColor: UIColor.black.cgColor, andThickness: 1)
        
        self.tableView.register(UINib(nibName: "PlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaylistTableViewCell")
        //プレイリスト一覧を取得
        playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.TITLE, sortOrder: MusicDataController.SortOrder.ASCENDING)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = playlists[indexPath.row] as PlaylistItem

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistTableViewCell") as! PlaylistTableViewCell

        if playlist.artwork?.image != nil {
            cell.playlistImageView?.contentMode = UIViewContentMode.scaleAspectFit
            cell.playlistImageView?.image = playlist.artwork?.image(at: CGSize(width:45, height:45))
        }
        cell.playlistLabel.text = playlist.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        giveId = playlists[indexPath.item].id
        playlistTitle = playlists[indexPath.item].title
        performSegue(withIdentifier: "PlaylistToSonglistSegue", sender: nil)
    }
    
    @IBAction func changeSort(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.TITLE, sortOrder: MusicDataController.SortOrder.ASCENDING)
        case 1:
            playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.LASTPLAYINGDATE, sortOrder: MusicDataController.SortOrder.DESCENDING)
        case 2:
            playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.DATEADDED, sortOrder: MusicDataController.SortOrder.DESCENDING)
        default:
            print("default")
        }
        self.tableView.reloadData()
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlaylistToSonglistSegue" {
            let vc = segue.destination as! SongTableViewController
            vc.receiveId = giveId
            vc.playlistTitle = playlistTitle
        }
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    


    
}
