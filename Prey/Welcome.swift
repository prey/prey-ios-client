//
//  Welcome.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class Welcome: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = true

        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool){
        // Show navigationBar when disappear this ViewController
        self.navigationController?.navigationBarHidden = false

        super.viewDidDisappear(animated)
    }
}

