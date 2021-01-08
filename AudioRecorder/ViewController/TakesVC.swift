//
//  TakesVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit
import CloudKit
import AVFoundation

/// List of recorded takes in app's documents directory and in iCloud
///
class TakesVC: UIViewController, UIPopoverPresentationControllerDelegate, TakesTableCellDelegate {
   
    @IBOutlet weak var takesTableView: UITableView!
    
    var takes = [String]()
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    var takeLoadedURL: URL?
    
    override func viewDidLoad() {
        print("TakesVC.viewDidLoad")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("TakesVC viewWillAppear")
        
        
        
        if Takes.sharedInstance.reloadFlag {
            takesTableView.reloadData()
        }
    }
    
    
    func reloadTakes() {
        takes = Takes().getAllTakeNames()
        
        takesTableView.reloadData()
    }
    
    
    /// Load all metadata for take, then trigger segue to 'TakeVC'.
    /// There are two sections in tableView: local takes and iCloud takes
    ///
    /// - parameter indexPath:  cell IndexPath
    /// - parameter take: Take object of selected cell
    ///
    func loadTake(indexPath: IndexPath, take: Take) {
        
        switch indexPath.section {
        // local takes
        case 0 :
            self.performSegue(withIdentifier: "TakeSegueIdentifier", sender: take)
        // iCloud takes
        case 1 :
            guard let takeRecord = Takes.sharedInstance.loadTakeRecord(takeName: take.takeName!) else {
                // no coredata take record -> create record (if user selects option to do so)
                createTakeRecordOption(take: take)
                return
            }
            self.performSegue(withIdentifier: "TakeSegueIdentifier", sender: takeRecord)
            
        default:
            print("No valid section index")
        }
    }
    
    /// Present option alert to user. CreateRecord option will move take from iCloud to app's documents directory
    ///
    /// - Parameter take: TableView cell Take object
    ///
    private func createTakeRecordOption(take: Take) {
        let recordOptionController = createTakeRecordOptionAlert(name: take.takeName!, completion: { createRecord in
            if createRecord {
                if take.storageState == .ICLOUD {
                    // icloud takes without coredata record have no url
                    // each iCloud take should have a CoreData record
                    take.cloudTakeToLocal() { result in
                        print(result)
                        if result == "complete" {
                            take.iCloudState = .NONE
                            take.storageState = .LOCAL
                            
                            self.takesTableView.reloadData()
                        }
                    }
                }
            }
        })
        
        self.present(recordOptionController, animated: true)
    }
    
    
    func moveTakeToLocal(take: Take) {
        do {
            try take.canMoveTakeToLocal()
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    /// Delete action from table cell. Take can be in app's document directory or in iCloud container.
    /// First let user confirm delete action (alert)
    ///
    /// - parameter indexPath: cell indexPath
    /// - parameter take: Tableview cell take
    ///
    func deleteTake(indexPath: IndexPath, take: Take) {
        var takeName = ""
        if indexPath.section == 0 {
            takeName = take.takeName!
        }
        
        if indexPath.section == 1 {
            guard let iCloudTakeName = Takes.sharedInstance.takesCloud[indexPath.row].takeName else {
                return
            }
            let takeExtension = Takes.sharedInstance.takesCloud[indexPath.row].takeType ?? "wav"
            takeName = "\(iCloudTakeName).\(takeExtension)"
        }
        
        let alertController = alertDeleteFile(name: takeName, completion: { deleteAction in
            if deleteAction {
                // delete action
                if indexPath.section == 0 {
                    let deleteAction = Takes().deleteTake(takeName: takeName)
                    if deleteAction == true {
                        let takeNameWithOutExtension = Takes().stripFileExtension(takeName)
                        if (self.coreDataController?.deleteTake(takeName: takeNameWithOutExtension))! {
                            //self.takes.remove(at: row)
                            Takes.sharedInstance.takesLocal.remove(at: indexPath.row)
                            self.takesTableView.reloadData()
                        } else {
                            // when file but no coredata entry
                            Takes.sharedInstance.takesLocal.remove(at: indexPath.row)
                            self.takesTableView.reloadData()
                        }
                    }
                }
                
                // iCloud take, delete CoreData and take in container
                if indexPath.section == 1 {
                    TakeCKRecordModel.sharedInstance.deleteTake(takeName: takeName) { result in
                        if result {
                            // iCloud file deleted, update coreData
                            //let takeNameWithOutExtension = Takes.sharedInstance.stripFileExtension(takeName)
                            if (self.coreDataController?.deleteTake(takeName: takeName))! {
                                Takes.sharedInstance.takesCloud.remove(at: indexPath.row)
                                self.takesTableView.reloadData()
                            } else {
                                Takes.sharedInstance.takesCloud.remove(at: indexPath.row)
                                DispatchQueue.main.async {
                                    self.takesTableView.reloadData()
                                }
                            }
                        }
                    }
                }
                
            } else {
                // cancel action
            }
        })
        
        self.present(alertController, animated: true)
    }
    
    
    /// Alert to get confirmation to delete a take
    ///
    /// - parameter name: name of take
    /// - parameter completion: closure to get alert result
    ///
    /// - Returns: Alert
    ///
    func alertDeleteFile(name: String, completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        
        let alertController = UIAlertController(title: "Delete", message: "Deleter Recording \(name)!", preferredStyle: .alert)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        return alertController
    }
    
    
    /// Alert to confirm moving take from iCloud to app's documents directory
    ///
    /// - Parameters:
    ///   - name:
    ///   - completion:
    /// - Returns:
    func createTakeRecordOptionAlert(name: String, completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        
        let alertController = UIAlertController(title: "Create Take Record", message: "Create a record for take \(name)!", preferredStyle: .alert)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        return alertController
    }
        
    /// Play take through ModalAudioPlayerVC. If take is in iCloud then make sure take can be played.
    ///
    /// - Parameters:
    ///   - indexPath: cell indexPath
    ///   - take: Take object
    func playTake(indexPath: IndexPath, take: Take ) {
        print("playTake Popover")
        let takeName = take.takeName!
        
        let popoverContentController = self.storyboard?.instantiateViewController(withIdentifier: "ModalAudioPlayerView") as? ModalAudioPlayerVC
        
        popoverContentController?.modalPresentationStyle = .popover
       // popoverContentController?.modalTransitionStyle = .crossDissolve
        popoverContentController?.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 320)
        popoverContentController?.view.backgroundColor = Colors.AVModal.background.toUIColor()
        
        if let popoverPresentationController = popoverContentController?.popoverPresentationController {
            popoverPresentationController.delegate = self
            // no arrow on popover
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            // with arrow
//            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.backgroundColor = Colors.Base.background.toUIColor()
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: 10, y: self.view.bounds.height / 2 + 120, width: self.view.frame.size.width, height: 240)
            
            
            if let popoverController = popoverContentController {
                present(popoverController, animated: true, completion: nil)
                popoverContentController?.takeName = takeName
                popoverContentController?.take = take
            }
        }
    }
    
    /// Play take through ModalAudioPlayerVC at url
    ///
    func playTake(indexPath: IndexPath, url: URL, takeCKRecord: TakeCKRecord) {
        let take = Takes.sharedInstance.takesCloud[indexPath.row]
        let popoverContentController = self.storyboard?.instantiateViewController(withIdentifier: "ModalAudioPlayerView") as? ModalAudioPlayerVC
        
        popoverContentController?.modalPresentationStyle = .popover
        popoverContentController?.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 320)
        popoverContentController?.view.backgroundColor = Colors.AVModal.background.toUIColor()
        
        if let popoverPresentationController = popoverContentController?.popoverPresentationController {
            popoverPresentationController.delegate = self
            // no arrow on popover
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            // with arrow
//            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.backgroundColor = Colors.Base.background.toUIColor()
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: 10, y: self.view.bounds.height / 2 + 120, width: self.view.frame.size.width, height: 240)
            
            
            if let popoverController = popoverContentController {
                present(popoverController, animated: true, completion: nil)
                popoverContentController?.takeName = takeCKRecord.name
                popoverContentController?.take = take
                popoverContentController?.takeURL = url
                
            }
        }
    }
    
    
    // MARK: ModalPopup Delegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    /// When playing take from iCloud show loading indicator view during loading take
    ///
    /// - Parameters:
    ///    - indexPath:
    ///    - takeCKRecord:
    func prepearToPlayICloudTake(indexPath: IndexPath, takeCKRecord: TakeCKRecord) {
//        if #available(iOS 13.0, *) {
            let indicatorView = IndicatorViewController()
            addChild(indicatorView)
            indicatorView.view.frame = view.frame
            view.addSubview(indicatorView.view)
            indicatorView.didMove(toParent: self)
//            let spinner = UIActivityIndicatorView(style: .large)
//            spinner.tintColor = UIColor.lightGray
//            spinner.startAnimating()
//            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
//        } else {
//            // Fallback on earlier versions
//            let spinner = UIActivityIndicatorView(style: .gray)
//            spinner.startAnimating()
//            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
//        }
        
       
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: takeCKRecord.record.recordID) { [unowned self] record, error in
            if let error = error {
                print(error.localizedDescription)
//                DispatchQueue.main.async {
//                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(self.downloadTapped))
//                }
            } else {
                if let record = record {
                    if let asset = record["take"] as? CKAsset {
                        takeLoadedURL = asset.fileURL
                        
                        DispatchQueue.main.async {
                            if (takeLoadedURL != nil) {
                                playTake(indexPath: indexPath, url: takeLoadedURL!, takeCKRecord: takeCKRecord)
                            }
                            indicatorView.willMove(toParent: nil)
                            indicatorView.view.removeFromSuperview()
                            indicatorView.removeFromParent()
                            //self.navigationItem.rightBarButtonItem = nil
                        }
                    }
                }
            }
        }
       
    }
    
    
    
    
    ///  Segue to full take page
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TakeSegueIdentifier" {
            guard let object = sender as? Take else { return }
            
            if let destinationVC = segue.destination as? TakeVC {
                destinationVC.take = object
            }
        }
        
        if segue.identifier == "CloudSegueIdentifier" {
            guard let object = sender as? Take else { return }
            
            if let destinationVC = segue.destination as? CloudVC {
                destinationVC.take = object
            }
        }
    }
    
    
    /// Cloud button action
    /// Present choice 
    ///
    @objc func takeCloudAction(_ sender: UIButton) {
        //let takeName = takes[sender.tag]
        if let cell = takesTableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? TakesTableDetailViewCell {
            self.performSegue(withIdentifier: "CloudSegueIdentifier", sender: cell.take)
        }
    }

    
    // MARK: TableCellDelegate
    
    /// Play take from app's document directory or take in app's iCloud container
    ///
    func playCellTake(cellIndex: IndexPath) {
        if cellIndex.section == 0 {
            if let cell = takesTableView.cellForRow(at: cellIndex) as? TakesTableDetailViewCell {
                playTake(indexPath: cellIndex, take: cell.take)
            }
            
        }
        
        // iCloud
        if cellIndex.section == 1 {
            if let cell = takesTableView.cellForRow(at: cellIndex) as? TakesTableDetailViewCell {
                // each iCloud take should have a CoreData record
                guard let takeCKRecord = TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: cell.take.takeName!) else {
                    print("No CoreData record for take \(cell.take.takeName ?? "unknown")")
                    return
                }
                
                prepearToPlayICloudTake(indexPath: cellIndex, takeCKRecord: takeCKRecord)
            }
        }
    }
    
    
    func loadCellMetadata(cellIndex: IndexPath) {
        //self.performSegue(withIdentifier: "TakeSegueIdentifier", sender: take)
        if let cell = takesTableView.cellForRow(at: cellIndex) as? TakesTableDetailViewCell {
            loadTake(indexPath: cellIndex, take: cell.take)
        }
        
    }
    
    func shareCellTake(cellIndex: IndexPath) {
        if let cell = takesTableView.cellForRow(at: IndexPath(row: cellIndex.row, section: cellIndex.section)) as? TakesTableDetailViewCell {
            self.performSegue(withIdentifier: "CloudSegueIdentifier", sender: cell.take)
        }
    }
    
    
    func deleteCellTake(cellIndex: IndexPath) {
        if let cell = takesTableView.cellForRow(at: cellIndex) as? TakesTableDetailViewCell {
            deleteTake(indexPath: cellIndex, take: cell.take)
        }
    }
    
}

extension TakesVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return takes.count
        switch section {
        case 0:
            return Takes.sharedInstance.takesLocal.count
        case 1:
            return Takes.sharedInstance.takesCloud.count
        default:
            return 0
        }
//        return Takes.sharedInstance.takesLocal.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TakesDetailsTableViewCellIdentifier", for: indexPath) as? TakesTableDetailViewCell else {fatalError("The dequeued cell is not an instance of TakesTableDetailViewCell")
        }
        
        if indexPath.section == 0 {
            let take = Takes.sharedInstance.takesLocal[indexPath.row]
            cell.take = take
        } else {
            let take = Takes.sharedInstance.takesCloud[indexPath.row]
            cell.take = take
        }
        
        
        if cell.take.takeLength > 0 {
            cell.playBtn.tag = indexPath.row
            //cell.playBtn.addTarget(self, action: #selector(playTakeForCell(_:)), for: .touchUpInside)
            
            cell.cloudBtn.tag = indexPath.row
            //cell.cloudBtn.addTarget(self, action: #selector(takeCloudAction(_:)), for: .touchUpInside)
            
            if cell.take.iCloudState == .ICLOUD {
                //cell.cloudBtn.layer.backgroundColor = UIColor.green.cgColor
                cell.cloudBtn.tintColor = UIColor.systemGreen
            }
            
            cell.metadataBtn.tag = indexPath.row
            //cell.metadataBtn.addTarget(self, action: #selector(loadMetadataForCell(_:)), for: .touchUpInside)
        }
       
        cell.trashBtn.tag = indexPath.row
        //cell.trashBtn.addTarget(self, action: #selector(deleteTake(_:)), for: .touchUpInside)
        
        cell.cellIndexPath = indexPath
        cell.delegate = self
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Local takes"
        case 1 :
            return "ICloud takes"
        default:
            return "Local takes"
        }
    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("TakesVC.didDelectRowAt: \(indexPath.row), name: \(takes[indexPath.row])")
//
//        let cell = tableView.cellForRow(at: indexPath)
//        //self.loadTake(row: indexPath.row, cell: cell!)
//        self.playTake(row: indexPath.row, cell: cell!)
//
//    }
    
//    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//        print("accesoryButtonTappedForRow")
//    }
    
//    @available(iOS 11.0, *)
//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        let action = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, completionHandler) in
//            self.deleteTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath)!)
//            completionHandler(true)
//        })
//
//        let configuration = UISwipeActionsConfiguration(actions: [action])
//        return configuration
//    }
//
//    @available(iOS 11.0, *)
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let action = UIContextualAction(style: .normal, title: "More", handler: { (action, view, completionHandler) in
//            self.loadTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath))
//            completionHandler(true)
//        })
//
//        let configuration = UISwipeActionsConfiguration(actions: [action])
//        return configuration
//    }
    
    
//    @available(iOS 10.0, *)
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        var actions = [UITableViewRowAction]()
//
//        let actionDelete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
//            self.deleteTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath)!)
//        }
//        let actionMore = UITableViewRowAction(style: .normal, title: "More") { (action, indexPath) in
//            self.loadTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath))
//        }
//
//        actions.append(actionDelete)
//        actions.append(actionMore)
//
//        return actions
//    }
}

protocol TakesTableCellDelegate {
    func loadCellMetadata(cellIndex: IndexPath)
    func playCellTake(cellIndex: IndexPath)
    func shareCellTake(cellIndex: IndexPath)
    func deleteCellTake(cellIndex: IndexPath)
}
