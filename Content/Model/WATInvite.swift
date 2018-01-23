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
 Class to be used to accept or reject invitations.
 */
public class WATInvite {
    
    ///The user unique identifier the invitation comes from.
    public internal(set) var from: String
    
    ///The room unique identifier the invitation refers to.
    public internal(set) var room: String
    
    ///Automatically updated status of the invitation : ONGOING, ACCEPTED, REJECTED.
    public internal(set) var status: String
    
    ///The text the user may read as an invitation message.
    public internal(set) var topic: String
    
    internal var uid: String?
    internal var _created: Double
    internal var _ended: Double?
    

    internal init(from: String,
                room: String,
                message: String) {
        
        self.from = from
        self.room = room
        self.status = Constant.Invite.Status.ongoing
        self.topic = message
        self.uid = ""
        self._created = round(NSDate().timeIntervalSince1970)
        self._ended = 0.0
    }
    
    internal init(from: String,
                  room: String,
                  status: String,
                  topic: String,
                  created: Double,
                  ended: Double?) {
        
        self.from = from
        self.room = room
        self.status = status
        self.topic = topic
        self.uid = ""
        self._created = created
        self._ended = ended
    }
    
    
//    MARK: - ACTIONS
    /**
     Accepts the received `WATInvite` instance.
     
     - Parameters:
        - completeCallback: Block called once invitation has been accepted. On failure, the first argument contains the details of the error while the second one returns the `WATInvite` instance.
     */
    public func accept(completeCallback:@escaping(_ error: Error?, _ info: WATInvite?) -> Void) {
        
        DLog("-oOo-  INVITE accept  -oOo-")
        
        guard let _ = WATManager.sharedInstance.base?.root?.toString() else {
            completeCallback(AppError.createError("Cannot accept the invitation. Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = WATManager.sharedInstance.current, let _ = WATManager.sharedInstance.current?.uid else {
            completeCallback(AppError.createError("Cannot accept the invitation. No user defined in the base for the authenticated person."), nil)
            return
        }
        
        guard let _ = uid else {
            completeCallback(AppError.createError("Cannot accept the invitation. No id is defined in the base for this invitation."), nil)
            return
        }
        
        if status == Constant.Invite.Status.ongoing {
            
            status = Constant.Invite.Status.accepted
            
            WATManager.sharedInstance.changeStatusInvite(self,
                                                         to: status) { (errorUpdt) in
                                                            completeCallback(errorUpdt, self)
            }
        } else {
            completeCallback(AppError.createError("Cannot accept an invitation that is not 'ongoing'."), self)
        }
    }
    
    
    /**
     Rejects the received `WATInvite` instance.
     
     - Parameters:
        - reason: text that explains why the invitation hasn't been accepted.
        - completeCallback: Block called once rejection has been received. On failure, the first argument contains the details of the error while the second one returns the `WATInvite` instance.
     */
    public func reject(reason: String,
                       completeCallback:@escaping(_ error: Error?, _ info: WATInvite) -> Void) {
        
        DLog("-oOo-  INVITE reject  -oOo-")
        
        guard let _ = WATManager.sharedInstance.base?.root?.toString() else {
            completeCallback(AppError.createError("Cannot reject the invitation. Webcom base root is nil. Check the URL."), self)
            return
        }
        
        guard let _ = WATManager.sharedInstance.current, let _ = WATManager.sharedInstance.current?.uid else {
            completeCallback(AppError.createError("Cannot reject the invitation. No user defined in the base for the authenticated person."), self)
            return
        }
        
        guard let _ = uid else {
            completeCallback(AppError.createError("Cannot reject the invitation. No id is defined in the base for this invitation."), self)
            return
        }
        
        if status == Constant.Invite.Status.ongoing {
            
            status = Constant.Invite.Status.rejected
            topic += "... REJECT CAUSE : " + reason
            
            WATManager.sharedInstance.changeStatusInvite(self,
                                                         to: status) { (errorUpdt) in
                                                            completeCallback(errorUpdt, self)
            }
        } else {
            completeCallback(AppError.createError("Cannot reject an invitation that is not 'ongoing'."), self)
        }
    }
    
    internal class func createObjectFrom(_ dicoObject: [String : Any?]) -> WATInvite {
        
        return WATInvite.init(from: dicoObject[Constant.Invite.Attribute.from] as! String,
                              room: dicoObject[Constant.Invite.Attribute.room] as! String,
                              status: dicoObject[Constant.Invite.Attribute.status] as! String,
                              topic: dicoObject[Constant.Invite.Attribute.topic] as! String,
                              created: dicoObject[Constant.Invite.Attribute.created] as! Double,
                              ended: dicoObject[Constant.Invite.Attribute.ended] as? Double)
    }
    
    internal class func createDicoInviteIn(room: WATRoom,
                                           withTopic msg: String) -> [String : Any?] {
        
        return [Constant.Invite.Attribute.from:WATManager.sharedInstance.current?.uid,
                Constant.Invite.Attribute.room:room.uid!,
                Constant.Invite.Attribute.status:Constant.Invite.Status.ongoing,
                Constant.Invite.Attribute.topic:msg,
                Constant.Invite.Attribute.created:round(NSDate().timeIntervalSince1970),
                Constant.Invite.Attribute.ended:0.0] as [String : Any?]
    }
}
