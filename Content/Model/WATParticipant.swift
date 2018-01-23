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
 Class to be used to get particpant information.
 */
public class WATParticipant {
    
    ///Role of the participant inside the room : OWNER, MODERATOR (not implemented yet) or NONE (guest).
    public var role: String
    
    ///Connection status of the participant : CONNECTED, NOT_CONNECTED or WAS_CONNECTED.
    public var status: String
    
    ///Date time the participant joined the room.
    public var _joined: Double
    
    internal var inviteId: String
    
    internal init(role: String, status: String) {
        
        self.role = role
        self.status = status
        self._joined = 0.0
        self.inviteId = ""
    }
    
    internal init(role: String, status: String, joined: Double, origin: String) {
        
        self.role = role
        self.status = status
        self._joined = 0.0
        self.inviteId = origin
    }
    
    internal class func createDicoParticipant() -> [String : Any?] {
        
        return [Constant.Participant.Attribute.role:Constant.Participant.Role.none,
                Constant.Participant.Attribute.status:Constant.Participant.Status.notConnected,
                Constant.Participant.Attribute.joined:0.0] as [String : Any?]
    }
    
    internal func updateParticipantStatus(notification: Notification) {
        
        
    }
    
    
}
