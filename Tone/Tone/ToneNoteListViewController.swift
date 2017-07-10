//
//  ToneNoteListViewController.swift
//  Tone
//
//  Created by Hisen on 2017/7/6.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import UIKit
import RealmSwift

private let reuseIdentifier = "ToneNoteCell"

class ToneNoteListViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    @IBOutlet weak var gotoRecordBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableFooterView: UIView!
    @IBOutlet weak var titleView: UIView!
    
    @IBOutlet weak var buttonToBottom: NSLayoutConstraint!
    
    var lastOffsetCapture: TimeInterval = 0.0
    var lastOffset = CGPoint()
    var buttonAnimated = false
    
    var dataSource : Results<ToneNote>!
    let realm = try! Realm()
    
    let transitionManager = TransitionManager()
    let panInteractionManager = PanInteractionManager()
    
    let audioManager = AudioManager(.playBack)
    
    var currentPlayingIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.delegate = self
        configUI()
        transitionManager.panInteractionManager = panInteractionManager
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readToneNotesAndUpdateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! RecordViewController
//        let destinationVC = segue.destination as! TestViewController
        transitionManager.baseFrame = gotoRecordBtn.frame
        destinationVC.transitioningDelegate = transitionManager
        panInteractionManager.wireToViewController(destinationVC)
    }
    
    @IBAction func unwindToViewController (sender: UIStoryboardSegue) {
        
    }

}

// MARK: UITableViewDelegate
extension ToneNoteListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ToneNoteCell
        if currentPlayingIndex != -1 {
            if currentPlayingIndex == indexPath.row {
                currentPlayingIndex = -1
                audioManager.stopPlay()
                cell.changeState(toPlay: false)
            } else {
                if (tableView.indexPathsForVisibleRows?.contains(IndexPath(row: currentPlayingIndex, section: 0)))! {
                    let cell = tableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as! ToneNoteCell
                    cell.changeState(toPlay: false)
                }
                let toneNote = dataSource[indexPath.row]
                currentPlayingIndex = indexPath.row
                let audioFileName = toneNote.fileName
                let url =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("toneNote/\(audioFileName)")
                audioManager.startPlay(url)
                cell.changeState(toPlay: true)
            }
        } else {
            let toneNote = dataSource[indexPath.row]
            currentPlayingIndex = indexPath.row
            let audioFileName = toneNote.fileName
            let url =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("toneNote/\(audioFileName)")
            audioManager.startPlay(url)
            cell.changeState(toPlay: true)
        }
    }

}

// MARK: UITableViewDataSource
extension ToneNoteListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ToneNoteCell
        cell.config(with: dataSource[indexPath.row], playFlag: indexPath.row == currentPlayingIndex)
        return cell
    }
    
}

// MARK: PlayProgressDelegate
extension ToneNoteListViewController: PlayProgressDelegate {
    
    func playFinished(_ force: Bool) {
        if (tableView.indexPathsForVisibleRows?.contains(IndexPath(row: currentPlayingIndex, section: 0)))! {
            let cell = tableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as! ToneNoteCell
            cell.changeState(toPlay: false)
        }
        currentPlayingIndex = -1
    }

}

// MARK: UIScrollViewDelegate
extension ToneNoteListViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            return
        }
        let currentOffset = scrollView.contentOffset
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture
        if timeDiff > 0.1 {
            if currentOffset.y > lastOffset.y {
                // hide
                animatedBtn(toShow: false)
            } else {
                // show
                animatedBtn(toShow: true)
            }
            lastOffset = currentOffset
            lastOffsetCapture = currentTime
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // show
        animatedBtn(toShow: true)
    }
    
    func animatedBtn(toShow show:Bool) {
        if buttonAnimated {
            return
        }
        
        if show {
            buttonToBottom.constant = 40
        } else {
            buttonToBottom.constant = -100
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.buttonAnimated = true
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.buttonAnimated = false
        }
    }
}

// MARK: UI
extension ToneNoteListViewController {
    func configUI() {
        gotoRecordBtn.layer.shadowColor = gotoRecordBtn.backgroundColor?.cgColor
        gotoRecordBtn.layer.shadowRadius = 5
        gotoRecordBtn.layer.shadowOpacity = 0.5
        gotoRecordBtn.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        titleView.layer.shadowColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1.0).cgColor
        titleView.layer.shadowRadius = 5
        titleView.layer.shadowOpacity = 0.5
        titleView.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        tableView.separatorColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1.0)
    }
}

// MARK: Private
extension ToneNoteListViewController {
    func readToneNotesAndUpdateUI() {
        dataSource = self.realm.objects(ToneNote.self).sorted(byKeyPath: "createDate")
        if dataSource.count > 0 {
            tableView.tableFooterView = UIView()
        } else {
            tableView.tableFooterView = tableFooterView
        }
        tableView.reloadData()
    }
}


