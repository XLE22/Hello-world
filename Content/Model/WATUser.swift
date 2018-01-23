/*
 * Webcom iOS Chat API
 * Build realtime apps. Share and sync data instantly between your clients
 *
 * Copyright (C) <2018> Orange
 *
 * This software is confidential and proprietary information of Orange.
 * You shall not disclose such Confidential Information and shall use it only in
 * accordance with the terms of the agreement you entered into.
 * Unauthorized copying of this file, via any medium is strictly prohibited.
 *
 * If you are Orange employee you shall use this software in accordance with
 * the Orange Source Charter (http://opensource.itn.ftgroup/index.php/Orange_Source_Charter)
 */


import Foundation


/**
 Class to be used to get user information.
 */
public class WATUser: NSObject {
    ///Last date time the user was connected.
    public var lastSeen: Double
    
    ///Phone number of the user.
    public var msisdn: String
    
    ///Name of the user.
    public var name: String
    
    ///Connection status of the user : CONNECTED or DISCONNECTED.
    public var status: String
    
    ///Unique identifier of the user.
    public var uid: String?
    
    internal init(name: String, msisdn: String) {//, email: String) {
        
        self.name = name
        self.status = ""
        self.lastSeen = 0.0
        self.msisdn = msisdn
        self.uid = ""
    }
    
    internal init(name: String,
                  status: String,
                  lastSeen: Double,
                  msisdn: String) {
        
        self.name = name
        self.status = status
        self.lastSeen = lastSeen
        self.msisdn = msisdn
        self.uid = ""
    }
    
    internal class func createDicoUser(_ name: String,
//                                       withMail email: String,
                                       andMSISDN msisdn: String) -> [String : Any?] {
        
        return [Constant.User.Attribute.name:name,
                Constant.User.Attribute.status:Constant.User.Status.disconnected,
                Constant.User.Attribute.lastSeen:0.0,
                Constant.User.Attribute.msisdn:msisdn] as [String : Any?]
//        ,
//                Constant.User.Attribute.email:email] as [String : Any?]
    }
    
    internal class func createObjectFrom(_ dicoObject: [String : Any?]) -> WATUser {
        
        return WATUser.init(name: dicoObject[Constant.Room.Attribute.name] as! String,
                            status: dicoObject[Constant.User.Attribute.status] as! String,
                            lastSeen: dicoObject[Constant.User.Attribute.lastSeen] as! Double,
                            msisdn: dicoObject[Constant.User.Attribute.msisdn] as! String)
//        ,
//                            email: dicoObject[Constant.User.Attribute.email] as! String)
    }
}
