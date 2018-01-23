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
 Class to be used to read a message content.
 */
public class WATMessage {
    
    ///Unique identifier of the message sender.
    public var from: String
    
    internal var roomId: String
    
    ///Text of the message to display.
    public var text: String
    
    internal var uid: String
    
    ///Date time creation of the message.
    public var _created: Double
    
    internal init(from: String, roomId: String, text: String) {
    
        self.from = from
        self.roomId = roomId
        self.text = text
        self.uid = ""
        self._created = round(NSDate().timeIntervalSince1970)
    }
    
    internal init(from: String,
                roomId: String,
                text: String,
                uid: String,
                created: Double) {
        
        self.from = from
        self.roomId = roomId
        self.text = text
        self.uid = uid
        self._created = created
    }
    
    internal class func createObjectWith(_ message: WATMessage) -> [String:Any?] {
        
        var finalMessage = [String: Any?]()
        
        finalMessage[Constant.Message.Attribute.uid] = message.uid
        finalMessage[Constant.Message.Attribute.text] = message.text
        finalMessage[Constant.Message.Attribute.from] = message.from
        finalMessage[Constant.Message.Attribute.roomId] = message.roomId
        finalMessage[Constant.Message.Attribute.created] = message._created
        
        return finalMessage
    }
}
