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

    @IBOutlet weak var toolbarCancelBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarSaveBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarCopyBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarBottom: UIToolbar!
    
    
    var takeCKRecordModel = TakeCKRecordModel()
    var cloudDataManager = CloudDataManager.sharedInstance
    
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
        
        navigationItem.title = "iCloud"
//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Set", style: .done, target: self, action: #selector(self.rightBarButtonAction(sender:)))

//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(self.rightBarButtonAction(sender:)))
        
        toolbarSaveBtn.isEnabled = false
        toolbarCopyBtn.isEnabled = false
        toolbarCancelBtn.isEnabled = false
        
        //toolbarBottom.viewWithTag(2)?.isHidden = true
        if let cancelItem = toolbarBottom.items?.first(where: { $0.tag == 2 }) {
            cancelItem.isEnabled = false
        }
        
        //tableView.allowsMultipleSelection = true
        
        //takeNames = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
        takeNames = Takes().getAllTakeNames()
        addToTakesLocal(takeNames: takeNames)
        
        let newTakes = cloudDataManager.getNewTakes()
        newTakeURLs = newTakes.url
        newTakeNames = newTakes.name
        
        //let cloudDriveTakes = cloudDataManager.getTakesInCloud()
        DispatchQueue.main.async {
            self.cloudDataManager.metadataQuery { result in
                print("metadataQuery with result \(result)")
                self.addToTakesInShare(takeURLs:  self.cloudDataManager.cloudURLs)
            }
        }
//        cloudDataManager.metadataQuery {result in
//            print("metadataQuery over!!!")
//            print(result)
//        }
        
        takeCKRecordModel.refresh {
            print("refreshClosure")
            if self.takeNames.count > 0 {
                self.takeNamesNew = self.takeCKRecordModel.getNewRecords(with: "name", in: self.takeNames)
                print(self.takeNamesNew.count)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
//        takeNames = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
//        if takeNames.count > 0 {
//            takeNamesNew = takeCKRecordModel.getNewRecords(with: "name", in: takeNames)
//        }
        
        //takeCKRecordModel.refresh()
    }
    
    
    private func addToTakesInShare(takeURLs: [URL]) {
        for item in takeURLs {
            takesInShare.append(TakeInShare(url: item, state: TakeInShare.State.CLOUD))
        }
        
        self.tableView.reloadData()
    }
    
    private func addToTakesLocal(takeNames: [String]) {
    
        for item in takeNames {
//            guard let itemURL = Takes().getUrlforFile(fileName: item) else {
//                return
//            }
            guard let itemURL = Takes().getURLForFile(takeName: item, fileExtension: "wav", takeDirectory: "takes") else {
                return
            }
            takesInShare.append(TakeInShare(url: itemURL, state: TakeInShare.State.LOCAL))
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
    
    
    /**
      Save selected takes (including metadata.json, notes, images) to CloudDrive
      Move whole directory
      
     */
    @IBAction func toolbarSaveBtnAction(_ sender: UIBarButtonItem) {
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
            cloudDataManager.takeFolderToCloud(takeName: takeName!, takeDirectory: "takes")
            takesInShare[(selectedRows?.first!)!].state = .CLOUD
            tableView.deselectRow(at: (selected?.first)!, animated: true)
            
            tableView.cellForRow(at: (selected?.first)!)?.accessoryType = .none
            if (tableView.indexPathsForSelectedRows == nil) {
                toolbarSaveBtn.isEnabled = false
                toolbarCopyBtn.isEnabled = false
            }
            
            tableView.reloadData()
        }
    }
    
    /**
     Copy take to CloudDrive
     
     */
    @IBAction func toolbarCopyBtnAction(_ sender: UIBarButtonItem) {
        let selected = tableView.indexPathsForSelectedRows
        var takeName:String?
        
        if selected != nil {
            let selectedRows = selected?.map { $0.row }
            var selectedNames: [String] = []
            for row in 0..<selectedRows!.count {
                selectedNames.append(takeNames[selectedRows![row]])
                
                takeName = takeNames[selectedRows![row]]
            }
            
            //cloudDataManager.takeFolderToDrive(takeName: takeName!)
//            do {
//                var sourceDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL.appendingPathComponent("test")
//                try FileManager.default.createDirectory(atPath: sourceDirURL.path, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//                print(error.localizedDescription)
//            }
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
            
//            var takeURL = sourceDirURL.appendingPathComponent(takeName!, isDirectory: false)
//            takeURL.appendPathExtension("wav")
//            urls.append(takeURL)
            
            let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    
    /**
     Return or create and return metadata json file url
     
     - parameters takeName: without file extension
     */
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
        cloudDataManager.copyFileToCloud()
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
        print("ShareCellBtn action in row \(sender.tag)")
        let takeName = takesInShare[sender.tag].name!
        cloudDataManager.takeFolderFromCloud(takeName: takeName)
        takesInShare[sender.tag].state = .LOCAL
        tableView.reloadData()
    }
}


extension ShareVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return takesInShare.count
//        return takeNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let takeStruct = takesInShare[indexPath.row]
        
        if takeStruct.state == .CLOUD {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
                fatalError("The dequeued cell is not an instance of ShareTableViewCell")
            }
            cell.takeNameLabel.text = takeStruct.name
            cell.takeStatusLabel.text = "inCloud"
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
        return nil
//        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("indexPathForSelectedRows: \(tableView.indexPathsForSelectedRows?.count ?? -1)")
        if let cell = tableView.cellForRow(at: indexPath) {
            if takesInShare[indexPath.row].state == .LOCAL {
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
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
            
            if (tableView.indexPathsForSelectedRows != nil) {
                toolbarSaveBtn.isEnabled = true
                toolbarCopyBtn.isEnabled = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if takesInShare[indexPath.row].state == .LOCAL {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            if (tableView.indexPathsForSelectedRows == nil) {
                toolbarSaveBtn.isEnabled = false
                toolbarCopyBtn.isEnabled = false
            }
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
    
    enum State {
        case LOCAL
        case DRIVE
        case CLOUD
    }
}
