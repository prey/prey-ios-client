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
    
    var command: String!
    var options: NSDictionary?
    
    // MARK: Functions    

    // Return Prey New Action
    class func newAction(withName:String) -> PreyAction? {
        
        let actionItem: PreyAction
        
        switch withName {

        case "location":
            actionItem = Location.sharedInstance
       
        default:
            return nil
        }
        
        return actionItem
    }
}