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


internal enum Constant {
    
    static let connectionNOK = "WATConnectionNOK" //Used to send notification when the WebSocket is NOK.
    static let connectionOK = "WATConnectionOK" //Used to send notification when the WebSocket is OK.
    static let disconnectionTime = 5.0 //Time in sec to claim a proper disconnection.
    static let webcomConnectionChildPath = ".info/connected" //Used to check the Websocket connectivity.
    
    enum SuffixPath {
        static let invites = "invites"
        static let messages = "messages"
        static let meta = "meta"
        static let msisdn = "msisdns"
        static let participants = "participants"
        static let rooms = "rooms"
        static let underscore = "_"
        static let users = "users"
    }
    
    
    enum Invite {
        
        enum Attribute {
            static let from = "from"
            static let room = "room"
            static let status = "status"
            static let topic = "topic"
            static let uid = "uid"
            static let created = "_created"
            static let ended = "_ended"
        }
        
        enum Status {
            static let ongoing = "ONGOING"
            static let accepted = "ACCEPTED"
            static let rejected = "REJECTED"
            static let canceled = "CANCELED"
        }
    }
    
    
    enum Message {
        
        enum Attribute {
            static let from = "from"
            static let roomId = "roomId"
            static let text = "text"
            static let uid = "uid"
            static let created = "_created"
        }
    }
    
    
    enum Meta {
        static let lastMsg = "lastMsg"
    }
    
    
    enum Participant {
        
        enum Attribute {
            static let role = "role"
            static let status = "status"
            static let joined = "_joined"
            static let origin = "inviteId"
        }
        
        enum Role {
            static let owner = "OWNER"
            static let moderator = "MODERATOR"
            static let none = "NONE"
        }
        
        enum Status {
            static let connected = "CONNECTED"
            static let notConnected = "NOT_CONNECTED"
            static let wasConnected = "WAS_CONNECTED"
        }
    }
    
    
    enum Room {
        
        enum Attribute {
            static let name = "name"
            static let owner = "owner"
            static let status = "status"
            static let uid = "uid"
            static let publik = "_public"
            static let created = "_created"
            static let closed = "_closed"
        }
        
        enum Status {
            static let closed = "CLOSED"
            static let opened = "OPENED"
        }
    }
    
    
    enum User {
        
        enum Attribute {
            static let name = "name"
            static let status = "status"
            static let lastSeen = "lastSeen"
            static let msisdn = "msisdn"
            static let email = "email"
            static let uid = "uid"
        }
        
        enum Status {
            static let connected = "CONNECTED"
            static let disconnected = "DISCONNECTED"
        }
    }
}


/**
 List of possible roles attributed to a guest.
 
 - OWNER: automatically given to the user who creates a room.
 - MODERATOR: not used in this version.
 - NONE: role of a guest inside a room.
 */
public enum WATInviteRole: String {
    case OWNER = "OWNER"
    case MODERATOR = "MODERATOR"
    case NONE = "NONE"
}
