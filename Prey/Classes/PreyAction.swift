//
//  PreyAction.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

class PreyAction : NSOperation {
   
    // MARK: Properties
    
    let command: String?
    let options: NSDictionary?
        
    init(withCommand:String, withOptions: NSDictionary?) {
        command = withCommand
        options = withOptions
    }
    
    // MARK: Functions    

    // Return Prey New Action
    class func newAction(withName:String, withCommand cmd:String, withOptions options:NSDictionary?) -> PreyAction? {
        
        let actionItem: PreyAction
        
        switch withName {

        case "location":
            actionItem = Location.sharedInstance//Location(withCommand:cmd, withOptions: options)
       
        default:
            return nil
        }
        
        return actionItem
    }
}