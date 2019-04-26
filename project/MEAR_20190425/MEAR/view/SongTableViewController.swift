//
//  SongTableViewController.swift
//  MEAR
//
//  Created by okura on 2018/10/15.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit

class SongTableViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var playlistTitle :String = ""
    
    private let musicDataController = MusicDataController.shared
    private let musicController: MusicController = AVMusicController.shared
    
    private var currentSongList: Array<SongItem> = []

    var receiveId: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = playlistTitle
        
        self.tableView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "SongTableViewCell")
        
        // プレイリスト内の曲一覧を取得
        self.currentSongList = musicDataController.getSongsWithPlaylist(id: self.receiveId, sortType: MusicDataController.SortType.DEFAULT)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentSongList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let songItem = currentSongList[indexPath.row] as SongItem
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCell") as! SongTableViewCell
        
        if songItem.artwork?.image != nil {
            cell.songImageView?.contentMode = UIViewContentMode.scaleAspectFit
            cell.songImageView?.image = songItem.artwork?.image(at: CGSize(width:45, height:45))
        }
        cell.songLabel.text = songItem.title
        cell.artistLabel.text = songItem.artist
        cell.timeLabel.text = songItem.duration
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let musicPlayerViewController = MusicPlayerViewController()
        musicPlayerViewController.indexId = indexPath.row
        musicPlayerViewController.currentSongList = currentSongList
        self.present(musicPlayerViewController, animated: true, completion: nil)
    }

    @IBAction func changeSort(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            // DEFAULT
            self.currentSongList = musicDataController.getSongsWithPlaylist(id: self.receiveId, sortType: MusicDataController.SortType.DEFAULT)
        case 1:
            // SHUFFLE
            self.currentSongList = musicDataController.getSongsWithPlaylist(id: self.receiveId, sortType: MusicDataController.SortType.SHUFFLE)
        case 2:
            // TITLE
            self.currentSongList = musicDataController.getSongsWithPlaylist(id: self.receiveId, sortType: MusicDataController.SortType.TITLE)

        default:
            print("")
        }
        
        self.tableView.reloadData()
    }
    

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
