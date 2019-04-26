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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.segmentedView.addBorder(toSide: UIView.ViewSide.Bottom, withColor: UIColor.black.cgColor, andThickness: 1)
        
        self.tableView.register(UINib(nibName: "PlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaylistTableViewCell")
        //プレイリスト一覧を取得
        playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)

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
        // 押されたときのcellのlabelの文字列をViewControllerに渡したいので、一旦、giveDataに入れとく
        giveId = playlists[indexPath.item].id
        // Segueを使った画面遷移を行う関数
        performSegue(withIdentifier: "PlaylistToSonglistSegue", sender: nil)
    }
    
    @IBAction func changeSort(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            print("0")
        case 1:
            print("1")
        case 2:
            print("2")
        default:
            print("3")
        }
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlaylistToSonglistSegue" {
            let vc = segue.destination as! SongTableViewController
            vc.receiveId = giveId
        }
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    


    
}
