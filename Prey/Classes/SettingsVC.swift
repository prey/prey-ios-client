//
//  SettingsVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

// Settings TableView Items
enum PreferencesViewSection {
    case Information, Settings, About, NumberPreferencesViewSection
}

// SectionInformation Items
enum SectionInformation {
    case CurrentLocation, Geofence, UpgradeToPro, NumberSectionInformation
}

// SectionSettings Items
enum SectionSettings {
    case CamouflageMode, DetachDevice, NumberSectionSettings
}

// SectionAbout Items
enum SectionAbout {
    case Version, Help, TermService, PrivacyPolice, NumberSectionAbout
}

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    // MARK: Properties

    @IBOutlet weak var tableView     : UITableView!
    
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: UITableViewDataSource
    
    // Number of sections
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return PreferencesViewSection.NumberPreferencesViewSection.hashValue
    }
    
    // Number of rows in section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberRows = 0
        
        switch section {
            
            // Information
        case PreferencesViewSection.Information.hashValue :
            
            numberRows = SectionInformation.NumberSectionInformation.hashValue
            if PreyConfig.sharedInstance.isPro {
                numberRows -= 1
            }
            
            // Settings
        case PreferencesViewSection.Settings.hashValue :
            numberRows = SectionSettings.NumberSectionSettings.hashValue
            
            // About
        case PreferencesViewSection.About.hashValue :
            numberRows = SectionAbout.NumberSectionAbout.hashValue
            
        default:
            numberRows = 0
        }
        
        return numberRows
    }
    
    // Title for Header in Section
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var titleSection = ""
        
        switch section {
        case PreferencesViewSection.Information.hashValue :
            titleSection = "Information".localized
            
        case PreferencesViewSection.Settings.hashValue :
            titleSection = "Settings".localized
            
        case PreferencesViewSection.About.hashValue :
            titleSection = "About".localized
            
        default:
            titleSection = ""
        }
        
        return titleSection
    }
    
    // Cell for row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        FIXME()
        
        let cellIdentifier  = "Cell"
        let cell            = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if cell == nil  {
            
        } 
        
        
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    
    // Height for header
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.About.hashValue ? 35 : 1
    }
    
    // Height for footer
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.Information.hashValue ? 35 : 1
    }
    
    // DisplayHeaderView
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header                  = view as! UITableViewHeaderFooterView
        let sizeFont:CGFloat        = (IS_IPAD) ? 14 : 12
        header.textLabel?.font      = UIFont(name: "TitilliumWeb-Bold", size:sizeFont)
        header.textLabel?.textColor = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 0.3)
    }
    /*
    // Row selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
     
    }
     */
}
