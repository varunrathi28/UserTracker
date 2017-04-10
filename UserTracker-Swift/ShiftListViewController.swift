//
//  ShiftListViewController.swift
//  UserTracker-Swift
//
//  Created by Varun Rathi on 10/04/17.
//  Copyright © 2017 vrat28. All rights reserved.
//

import UIKit

class ShiftListViewController: UIViewController {

    var datasource:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    
    func setUpSegmentedControl()
    {
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}

extension ShiftListViewController : UITableViewDelegate
{
    
}

extension ShiftListViewController : UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    //    return datasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}


