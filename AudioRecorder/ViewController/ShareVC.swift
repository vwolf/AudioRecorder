//
//  ShareVC.swift
//  AudioRecorder
//
//  Created by Wolf on 14.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class ShareVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

//    @IBOutlet weak var toolbarCancelBtn: UIBarButtonItem!
//    @IBOutlet weak var toolbarSaveBtn: UIBarButtonItem!
//    @IBOutlet weak var toolbarCopyBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarBottom: UIToolbar!
    
    
    var takeCKRecordModel = TakeCKRecordModel()
    //var cloudDataManager = CloudDataManager.sharedInstance
    
    var takeNames = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var takeNamesNew = [String]()
    var newTakeURLs: [URL] = []
    var newTakeNames: [String] = []
    
    var metaDataQuery: NSMetadataQuery?
    
    var takesInShare: [TakeInShare] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "iCloud & iDrive"
//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Set", style: .done, target: self, action: #selector(self.rightBarButtonAction(sender:)))

//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(self.rightBarButtonAction(sender:)))
        
//        toolbarSaveBtn.isEnabled = false
//        toolbarCopyBtn.isEnabled = false
//        toolbarCancelBtn.isEnabled = false
        
        //toolbarBottom.viewWithTag(2)?.isHidden = true
        if let cancelItem = toolbarBottom.items?.first(where: { $0.tag == 2 }) {
            cancelItem.isEnabled = false
        }
        
        //tableView.allowsMultipleSelection = true
    
//        takeNames = Takes().getAllTakeNames()
//        addToTakesLocal(takeNames: takeNames)
        
        // get all takes in iDrive which are not in App Document -> Folder
        let newTakes = CloudDataManager.sharedInstance.getNewTakes()
        newTakeURLs = newTakes.url
        newTakeNames = newTakes.name
        
        //let cloudDriveTakes = cloudDataManager.getTakesInCloud()
        DispatchQueue.main.async {
            CloudDataManager.sharedInstance.metadataQuery { [self] result in
                print("metadataQuery with result \(result)")
                self.addToTakesInShare(takeURLs:  CloudDataManager.sharedInstance.cloudURLs, takeState: .DRIVE)
            }
        }
//        cloudDataManager.metadataQuery {result in
//            print("metadataQuery over!!!")
//            print(result)
//        }
        
        /// query iCloudDrive (folder for app) and add to TakesInShare
        takeCKRecordModel.refresh {
            print("refreshClosure")
            if self.takeCKRecordModel.records.count > 0 {
                var takes = [String: URL]()
                for take in self.takeCKRecordModel.takeRecords {
                    takes[take.name] = take.audioAsset.fileURL
                }
                
                DispatchQueue.main.async {
                    self.addToTakesInShare(takes: takes, takeState: .CLOUD)
                }
            }
        }
        
        /// query Dropbox if activated
        if UserDefaults.standard.bool(forKey: "useDropbox") {
            let dropboxTakes = DropboxManager.sharedInstance.takesInDropbox
            
            var takes = [String: URL]()
            for take in dropboxTakes {
                takes[take] = URL(string: take)
            }
            DispatchQueue.main.async {
                self.addToTakesInShare(takes: takes, takeState: .DROPBOX)
            }
        }
//        takeNames = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
//        if takeNames.count > 0 {
//            takeNamesNew = takeCKRecordModel.getNewRecords(with: "name", in: takeNames)
//        }
        
//        takeCKRecordModel.refresh(completion: <#() -> Void#>)
    }
    
    /// Takes can be in iCloudDrive
    ///
    private func addToTakesInShare(takeURLs: [URL], takeState: TakeInShare.State) {
        for item in takeURLs {
            takesInShare.append(TakeInShare(url: item, state: takeState))
        }
        
        self.tableView.reloadData()
    }
    
    /// Takes in iCloud
    /// Switch state of take to .CLOUD
    ///
    /// - parameter takes: takes in apps documents directory
    /// - parameter takeState: should be .LOCAL
    ///
    private func addToTakesInShare(takes: [String: URL], takeState: TakeInShare.State ) {
        for item in takes {
            
            if takesInShare.contains(where: { $0.name == item.key }) {
                if let idx = (takesInShare.firstIndex(where: { $0.name == item.key }))  {
                    takesInShare[idx].state = .CLOUD
                }
            } else {
                takesInShare.append(TakeInShare(url: item.value, state: takeState, name: item.key))
            }
        }
        self.tableView.reloadData()
    }
    
    private func addToTakesLocal(takeNames: [String]) {
    
        for item in takeNames {
            if let itemURL = Takes().getURLForFile(takeName: item, fileExtension: "wav", takeDirectory: "takes")  {
                takesInShare.append(TakeInShare(url: itemURL, state: TakeInShare.State.LOCAL))
            }
            //takesInShare.append(TakeInShare(url: itemURL, state: TakeInShare.State.LOCAL))
        }
    }
    
    
//    func metadataQuery() {
//        var iCloudURL = cloudDataManager.getDocumentDiretoryURL()
//        print("metadataQuery at: \(iCloudURL)")
//        metaDataQuery = NSMetadataQuery()
////        metaDataQuery?.predicate = NSPredicate(format: "%K BEGINSWITH %@", argumentArray: [NSMetadataItemPathKey, iCloudURL.path])
//        metaDataQuery?.predicate = NSPredicate(format: "%K.pathExtension = %@", argumentArray: [NSMetadataItemURLKey, "wav"])
//        //metaDataQuery?.predicate = NSPredicate(format: "%K like 'SampleDoc.txt'", NSMetadataItemFSNameKey)
//        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
//
//        NotificationCenter.default.addObserver(self, selector: #selector(metadataQueryDidFinish(_ :)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery)
//
//        metaDataQuery?.start()
//    }
//
//    @objc func metadataQueryDidFinish(_ notification: Notification) -> Void {
//        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
//        query.disableUpdates()
//
//        let result = query.results
//        for item in result {
//            let itemURL = (item as AnyObject).value(forAttribute: NSMetadataItemURLKey) as! URL
//            print(itemURL.path)
//        }
//
//    }
    
    
    
    /// Save selected takes (including metadata.json, notes, images) to CloudDrive
    /// Move whole directory
    ///
    @IBAction func toolbarCloudDriveBtnAction(_ sender: UIBarButtonItem) {
        //copyFilesToDrive()
        
        let selected = tableView.indexPathsForSelectedRows
        var takeName:String?
        
        if selected != nil {
            let selectedRows = selected?.map { $0.row }
            var selectedNames: [String] = []
            for row in 0..<selectedRows!.count {
                selectedNames.append(takeNames[selectedRows![row]])
                takeName = takeNames[selectedRows![row]]
                
                // add metadataFile (*.json)
                if let metadataURL = metadataJsonForTake(takeName: takeName!) {
                   print("metadata: \(metadataURL)")
                }
            }
            
            // test with just one selected take
            CloudDataManager.sharedInstance.takeFolderToCloud(takeName: takeName!, takeDirectory: "takes")
            takesInShare[(selectedRows?.first!)!].state = .DRIVE
            tableView.deselectRow(at: (selected?.first)!, animated: true)
            
            tableView.cellForRow(at: (selected?.first)!)?.accessoryType = .none
//            if (tableView.indexPathsForSelectedRows == nil) {
//                toolbarSaveBtn.isEnabled = false
//                toolbarCopyBtn.isEnabled = false
//            }
            
            tableView.reloadData()
        }
    }
    
    /**
     Copy take to CloudDrive
     
     */
    @IBAction func toolbarICloudBtnAction(_ sender: UIBarButtonItem) {
        let selected = tableView.indexPathsForSelectedRows
        var takeName:String?
        
        if selected != nil {
            let selectedRows = selected?.map { $0.row }
            var selectedNames: [String] = []
            for row in 0..<selectedRows!.count {
                selectedNames.append(takeNames[selectedRows![row]])
                
                takeName = takeNames[selectedRows![row]]
            }

            var urls: [URL] = []
            
//            if let metadataURL = metadataJsonForTake(takeName: takeName!) {
//                urls.append(metadataURL)
//            }
            
            var sourceDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL.appendingPathComponent("takes")
            sourceDirURL.appendPathComponent(takeName!, isDirectory: true)
            
            do {
                let dirContents = try FileManager.default.contentsOfDirectory(at: sourceDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                urls.append(contentsOf: dirContents)
                
            } catch {
                print(error.localizedDescription)
            }
            
            // get wav file
            if let wavFile = urls.firstIndex(where: { $0.pathExtension == "wav"}) {
                takeCKRecordModel.addTake(url: urls[wavFile])
            }
//            takeCKRecordModel.addTake(url: urls.first!)
            // opens activityController -> not here
//            let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
//
//            self.present(controller, animated: true, completion: nil)
//            if let popover = controller.popoverPresentationController {
//                popover.sourceView = self.view
//            }
        }
    }
    
    
    
    /// Return or create and return metadata json file url
    ///
    /// - parameters takeName: without file extension
    ///
    func metadataJsonForTake(takeName: String) -> URL? {
//         metadataFile? (*.json)
                if let url = Takes().getURLForFile(takeName: takeName, fileExtension: "wav", takeDirectory: "takes") {
                    let metadataFileURL = url.deletingPathExtension().appendingPathExtension("json")
                    if FileManager.default.fileExists(atPath: metadataFileURL.path) {
//                        selectedNames.append(metadataFileURL.lastPathComponent)
                        return metadataFileURL
                    } else {
                        // no metadata json file -> create one
//                        let takeName = url.deletingPathExtension().lastPathComponent
                        if Takes().makeMetadataFile(takeName: takeName) == true {
//                            selectedNames.append(metadataFileURL.lastPathComponent)
                            return metadataFileURL
                        }
                    }
                }
        return nil
    }
    
    
    func copyFilesToDrive() {
        CloudDataManager.sharedInstance.copyFileToCloud()
    }
    
    @IBAction func toolbarCancelBtnAction(_ sender: UIBarButtonItem) {
    }
    
    @objc func rightBarButtonAction(sender: UIBarButtonItem) {
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "EditShareClientSegue":
            let destination = segue.destination as? SettingsVC
            
            if let viewControllers = self.navigationController?.viewControllers {
                if (viewControllers.count >= 1) {
                    let previousViewController = viewControllers[0] as! RecordVC
                    let settings = previousViewController.settings
                    let userSettings = previousViewController.userSettings
                    
                    destination?.settings = settings
                    let displaySettingData = settings?.settingForDisplay(name: userSettings?.recordingsetting ?? "default")
                    destination?.displaySetting.append(displaySettingData!)
                    
                    destination?.userSettings = userSettings
                    let displayUserSettingData = settings!.userSettingsForDisplay(data: (userSettings?.userSettingsForDisplay())!)
                    destination?.displaySetting.append(displayUserSettingData)
                    
                    destination?.parentIsShareVC = true
                }
            }
            
//            guard let parentVC = parent as? RecordVC else {
//                return
//            }
//            if parentVC.settings != nil {
//                destination?.settings = parentVC.settings
//
//                let displaySettingData = parentVC.settings!.settingForDisplay(name: parentVC.userSettings?.recordingsetting ?? "default" )
//                destination?.displaySetting.append(displaySettingData)
//            }
            
            
            
        default:
            NSLog("Navigation: Segue with unknown identifier")
        }
    }
    
    @objc func shareCellBtn(sender: UIButton) {
        print("ShareCellBtn action in row \(sender.tag), state: \(takesInShare[sender.tag].state)")
        
        switch takesInShare[sender.tag].state {
        case .DRIVE :
            presentOptions(takeName: takesInShare[sender.tag].name!, idx: sender.tag)
//            let takeName = takesInShare[sender.tag].name!
//            CloudDataManager.sharedInstance.takeFolderFromCloud(takeName: takeName)
//            takesInShare[sender.tag].state = .LOCAL
            
        case .CLOUD :
            presentOptions(takeName: takesInShare[sender.tag].name!, idx: sender.tag)
            //deleteAlert(takeName: takesInShare[sender.tag].name!, idx: sender.tag)
            //takeCKRecordModel.deleteTake(at: sender.tag)
            //takesInShare[sender.tag].state = .LOCAL
        
        case .DROPBOX :
            presentOptions(takeName: takesInShare[sender.tag].name!, idx: sender.tag)
            
        default:
            print("Do nothing")
        }
        
        tableView.reloadData()
    }
    
    
    func deleteAlert(takeName: String, idx: Int) {
        let alertController = alertDeleteFile(name: takeName, completion: { [self] deleteAction in
            if deleteAction {
                // delete action
                if deleteAction == true {
                    //takeCKRecordModel.deleteTake(takeName: takeName)
                    takesInShare[idx].state = .LOCAL
                    tableView.reloadData()
                }
            } else {
                // cancel action
            }
        })
        
        self.present(alertController, animated: true)
    }
    
    func presentOptions(takeName: String, idx: Int) {
        let alertController = optionAlert(name: takeName, completion: { optionAction in
            switch optionAction {
            case "delete":
                print(optionAction)
                
            case "restore" :
                print(optionAction)
                
            default:
                print("nothing")
            }
        })
        
        self.present(alertController, animated: true)
    }
    
    
    /**
     Alert to get confirmation to delete a take
     
     - parameter name: name of take
     - parameter completion: closure to get alert result
     
     - Returns: Alert
     */
    func alertDeleteFile(name: String, completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        
        let alertController = UIAlertController(title: "Delete", message: "Remove Recording \(name) from iCloud?", preferredStyle: .alert)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        return alertController
    }
    
    
    /// Option alert for shared takes
    func optionAlert(name: String, completion: @escaping (String) -> ()) -> UIAlertController {
        
        let deleteAction = UIAlertAction(title: "Delete Take", style: .destructive) { _ in
            completion("delete")
        }
        
        let restoreAction = UIAlertAction(title: "Restore Take", style: .default) { _ in
            completion("restore")
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion("cancel")
        }
        
        let alertController = UIAlertController(title: "Do", message: "Choose Action", preferredStyle: .alert)
        alertController.addAction(deleteAction)
        alertController.addAction(restoreAction)
        alertController.addAction(cancel)
        
        return alertController
    }
}


extension ShareVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return takesInShare.count
//        return takeNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let takeStruct = takesInShare[indexPath.row]
        
        if takeStruct.state == .DRIVE {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
                fatalError("The dequeued cell is not an instance of ShareTableViewCell")
            }
            cell.takeNameLabel.text = takeStruct.name
            cell.takeStatusLabel.text = "in iCloud Drive"
            cell.cloudBtn.tag = indexPath.row
            cell.cloudBtn.addTarget(self, action: #selector(shareCellBtn(sender:)), for: .touchUpInside)
            return cell
        }
        
        
        if takeStruct.state == .CLOUD {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
                fatalError("The dequeued cell is not an instance of ShareTableViewCell")
            }
            cell.takeNameLabel.text = takeStruct.name
            cell.takeStatusLabel.text = "in iCloud"
            cell.cloudBtn.tag = indexPath.row
            cell.cloudBtn.addTarget(self, action: #selector(shareCellBtn(sender:)), for: .touchUpInside)
            
            //cell.cloudBtn.layer.backgroundColor = CGColor.init(red: 0x21/255, green: 0x20/255, blue: 0x1f/255, alpha: 1.0)
                
                //CGColor(red: 0x21, green: 0x20/255, blue: 0x1f/255, alpha: 1.0)
//            cell.cloudBtn.tintColor = UIColor.green
            return cell
        }
        
        if takeStruct.state == .DROPBOX {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DropboxTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
                fatalError("The dequeued cell is not an instance of ShareTableViewCell")
            }
            cell.takeNameLabel.text = takeStruct.name
            cell.takeStatusLabel.text = "in Dropbox"
            cell.cloudBtn.tag = indexPath.row
            cell.cloudBtn.addTarget(self, action: #selector(shareCellBtn(sender:)), for: .touchUpInside)
            return cell
        }
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocalTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
            fatalError("The dequeued cell is not an instance of ShareTableViewCell")
        }
        cell.takeNameLabel.text = takeStruct.name
        cell.takeStatusLabel.text = "local file"
        
        return cell
        
        
        //        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
        //            fatalError("The dequeued cell is not an instance of ShareTableViewCell")
        //        }
        
        
        
        
        //cell.takeNameLabel.text = takeNames[indexPath.row]
        //        cell.accessoryType = .none
        //        cell.accessoryView = .none
        
        
        //        if newTakeNames.contains( takeNames[indexPath.row]) {
        //            cell.takeStatusLabel.text = "not in Cloud"
        //        } else {
        //            cell.takeStatusLabel.text = "in Cloud"
        //        }
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if takesInShare[indexPath.row].state == .LOCAL {
//        if newTakeNames.contains( takeNames[indexPath.row]) {
            return indexPath
        }
        //return nil
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("indexPathForSelectedRows: \(tableView.indexPathsForSelectedRows?.count ?? -1)")
        print("indexpath.row: \(indexPath.row)")
        if let cell = tableView.cellForRow(at: indexPath) {
            
            presentOptions(takeName: takesInShare[indexPath.row].name!, idx: indexPath.row)
//            if takesInShare[indexPath.row].state == .LOCAL {
//                if cell.accessoryType == .none {
//                    cell.accessoryType = .checkmark
//                } else {
//                    cell.accessoryType = .none
//                }
//            }
//            if newTakeNames.contains( takeNames[indexPath.row]) {
//                if cell.accessoryType == .none {
//                    cell.accessoryType = .checkmark
//                } else {
//                    cell.accessoryType = .none
//                }
//            } else {
//                if cell.accessoryType == .none {
//                    cell.accessoryType = .detailButton
//                } else {
//                    cell.accessoryType = .none
//                }
//            }
            
//            if (tableView.indexPathsForSelectedRows != nil) {
//                toolbarSaveBtn.isEnabled = true
//                toolbarCopyBtn.isEnabled = true
//            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if takesInShare[indexPath.row].state == .LOCAL {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
//            if (tableView.indexPathsForSelectedRows == nil) {
//                toolbarSaveBtn.isEnabled = false
//                toolbarCopyBtn.isEnabled = false
//            }
        } else {
            print("didDeselectRowAt")
        }
    }
   
}


class ShareTableViewCell: UITableViewCell {
    
    @IBOutlet weak var takeNameLabel: UILabel!
    @IBOutlet weak var takeStatusLabel: UILabel!
    @IBOutlet weak var cloudBtn: UIButton!
    
}



struct TakeInShare {
    
    var name: String?
    var url: URL
    var state: State
    
    init(url: URL, state: State) {
        self.url = url
        self.state = state
        
        self.name = url.lastPathComponent
    }
    
    init(url: URL, state: State, name: String) {
        self.url = url
        self.state = state
        self.name = name
    }
    
    init(state: State, name: String) {
        self.url = URL(string: name)!
        self.state = state
        self.name = name
    }
    
    
    enum State {
        case LOCAL
        case DRIVE
        case CLOUD
        case LOCALCLOUD
        case DROPBOX
    }
}
