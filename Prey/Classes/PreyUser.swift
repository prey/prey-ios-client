//
//  PreyUser.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/1/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

import Foundation

class PreyUser: NSObject {
    
    var name: String?
    var email: String?
    var country: String?
    var password: String?
    var repassword: String?
    var apiKey: String?
    var isPro: Bool?
}

/*
+ (void)allocWithEmail:(NSString*)emailUser password:(NSString*)passwordUser  withBlock:(void (^)(User *user, NSError *error))block;
+ (void)createNew:(NSString*)nameUser email:(NSString*)emailUser password:(NSString*)passwordUser repassword:(NSString*)repasswordUser  withBlock:(void (^)(User *user, NSError *error))block;
*/