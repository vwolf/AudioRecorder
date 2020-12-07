//
//  LoadVC.swift
//  AudioRecorder
//
//  Created by Wolf on 29.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class LoadVC: UIViewController {
    
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController {
        didSet {
            print("LoadVC -> coreDataController")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LoadVC.viewDidLoad")
        view.backgroundColor = Colors.Base.background.toUIColor()
        
        
    }
    
    public func msgFromDelegate() {
        print("Msg from SceneDelegate")
        
        self.performSegue(withIdentifier: "SegueToRecordVC", sender: nil)
    }
}
