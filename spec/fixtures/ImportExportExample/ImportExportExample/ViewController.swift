//
//  ViewController.swift
//  ImportExportExample
//
//  Created by Viktoras Laukevičius on 13/02/2017.
//  Copyright © 2017 Xlocalize. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = NSLocalizedString("only_single", tableName: "only_singles", comment: "Only single comment")
        _ = NSLocalizedString("only_other_single", tableName: "and_plurals", comment: "Only single comment")
        _ = String(format: NSLocalizedString("users_count", tableName: "and_plurals", comment: ""), 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

