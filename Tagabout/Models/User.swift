//
//  User.swift
//  Tagabout
//
//  Created by Karun Pant on 03/03/18.
//  Copyright © 2018 Tagabout. All rights reserved.
//

import UIKit

struct LoginData : Codable{
    var action : String?
    var authToken : String?
    var message : String?
    var loginDetail : LoginDetails?
}

struct LoginDetails: Codable {
    var sourceId : Int?
    var contactId : Int?
    var role : Int?
    var skipVideo : Bool?
    var showVideo : Bool?
    var videoUrl : String?
    var contactName : String?
    var sourceName : String?
    var mobile : String?
    var sourceType : String?
    
}
