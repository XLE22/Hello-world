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
import Webcom


//public enum Role {
//    static let owner = "OWNER"
//    static let moderator = "MODERATOR"
//    static let none = "NONE"
//}


/**
 Class to be used to get room information and make actions inside this room.
 */
public class WATRoom: NSObject {
    
    ///Name of the room.
    public var name: String
    
    internal var owner: String
    
    ///Room status : CLOSED or OPENED.
    public var status: String
    
    internal var uid: String?
    internal var _public: Bool
    internal var _created: Double
    internal var _closed: Double?
    
    internal init(name: String,
                owner: String) {
        
        self.name = name
        self.owner = owner
        self.status = "OPENED"
        self.uid = ""
        self._public = false
        self._created = round(NSDate().timeIntervalSince1970)
        self._closed = nil
    }
    
    internal init(name: String,
                owner: String,
                status: String,
                _public: Bool,
                _created: Double,
                _closed: Double?) {
        
        self.name = name
        self.owner = owner
        self.status = status
        self.uid = ""
        self._public = _public
        self._created = _created
        self._closed = _closed
    }
 

// MARK: - ACTIONS
    /**
     Invites a registered user.
     
     - Parameters:
        - user: The `WATUser` instance to invite.
        - role: The role the guest will have : other choice than NONE (guest) isn't taken into account yet.
        - message: The text that may be read as an invitation message.
        - completeCallback: Block called once the invitation has been registered. On failure, the first argument contains the details of the error while the others respectively represent the `WATRoom` instance where the communication should take place and the created `WATInvite` instance.
     */
    public func invite(user:WATUser,
                       role: WATInviteRole,
                       messsage: String,
                       completeCallback:@escaping(_ error: Error?, _ room: WATRoom, _ invite: WATInvite?) -> Void) {
        
        guard let _ = self.uid else {
            completeCallback(AppError.createError("The room id is nil."), self, nil)
            return
        }
        
        guard let _ = user.uid else {
            completeCallback(AppError.createError("User id is nil."), self, nil)
            return
        }
        
        guard let _ = WATManager.sharedInstance.current?.uid else {
            completeCallback(AppError.createError("The sender id is nil."), self, nil)
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms + "/" + uid! + "/" + Constant.SuffixPath.participants + "/" + user.uid!
        
        let wbcRoomIdParticipant = WCWebcom(url: participantPath)
        
        wbcRoomIdParticipant?.onceEventType(WCEventType.value,
                                             withCallback: { (data, str) in
                                                
                                                guard let _ = data?.value else {
                                                    
                                                    let dico = WATInvite.createDicoInviteIn(room: self,  withTopic: messsage)
                                                    let invitation = WATInvite.createObjectFrom(dico)
                                                    
                                                    var userIdInvitePath = (WATManager.sharedInstance.base?.root?.toString())! as String
                                                    userIdInvitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites + "/" + user.uid!
                                                    
                                                    let wbcUserIdInvites = WCWebcom(url: userIdInvitePath)
                                                    
                                                    let dispatchGroup = DispatchGroup()
                                                    
                                                    dispatchGroup.enter()
                                                    let newInvite =  wbcUserIdInvites?.push(dico as NSObject?,
                                                                           onComplete: { error in
                                                                            
                                                                            guard let _ = error else {
                                                                                dispatchGroup.leave()
                                                                                return
                                                                            }
                                                                            
                                                                            completeCallback(error, self, nil)
                                                    })
                                                    
                                                    dispatchGroup.notify(queue: .main){
                                                        
                                                        let valUpdate = newInvite?.name ?? (String)(round(NSDate().timeIntervalSince1970))
                                                        let updateDico = [Constant.Invite.Attribute.uid: valUpdate]
                                                        newInvite?.update(updateDico as NSObject,
                                                                          onComplete: { (errorUpdt) in
                                                                            
                                                                            guard let _ = errorUpdt else {
                                                                                
                                                                                invitation.uid = valUpdate
                                                                                var dico = WATParticipant.createDicoParticipant()
                                                                                dico[Constant.Participant.Attribute.origin] = invitation.uid
                                                                                
                                                                                wbcRoomIdParticipant?.set(dico as NSObject?,
                                                                                                          onComplete: { errorPart in
                                                                                                            completeCallback(errorPart, self, invitation)
                                                                                })
                                                                                return
                                                                            }
                                                                            
                                                                            completeCallback(errorUpdt, self, nil)
                                                        })
                                                    }
                                                    return
                                                }
                                                
                                                completeCallback(AppError.createError("This user is already a participant of this room."), self, nil)
        })
    }
 
    
    /**
     Joins the room this method is applied to.
     When fired, the participant status becomes CONNECTED and an automatic mecanism updates this status to WAS_CONNECTED in case of a disconnection.
     
     - Parameters:
        - completeCallback: Block called once the action has been registered. On failure, the first argument contains the details of the error.
     */
    public func join(completeCallback:@escaping(_ error: Error?) -> Void) {
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            completeCallback(AppError.createError("Your id is unknown in the database."))
            return
        }
        
        guard let _ =  uid else {
            completeCallback(AppError.createError("Room id is unknown in the database."))
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms + "/" + uid! + "/" + Constant.SuffixPath.participants
        
        let wbcParticipants = WCWebcom(url: participantPath)
        wbcParticipants?.onceEventType(.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            completeCallback(AppError.createError("Unknown participant id in the database."))
                                            return
                                        }
                                        
                                        if let participants = (data!.value as? [String: Any?]) {

                                            for (key, value) in participants {
                                                if (key == userId!) {
                                                    
                                                    if let participant = value as? [String: Any?] {
                                                        if (participant[Constant.Participant.Attribute.origin] as! String) != "" {
                                                            
                                                            //Updates the invitation to 'accepted' whatever the value.
                                                            let dico = [Constant.Invite.Attribute.status:Constant.Invite.Status.accepted]
                                                            let invitationId = participant[Constant.Participant.Attribute.origin] as! String
                                                            
                                                            var invitationPath = (WATManager.sharedInstance.base?.root?.toString())! as String
                                                            invitationPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites
                                                            invitationPath += "/" + (WATManager.sharedInstance.current?.uid)! + "/" + invitationId
                                                            
                                                            let wbcInvitations = WCWebcom(url: invitationPath)
                                                            wbcInvitations?.update(dico as NSObject,
                                                                                   onComplete: { errUpdt in
                                                                
                                                                guard let _ = errUpdt else {
                                                                
                                                                    WATManager.sharedInstance.webcomParticipantPath = participantPath
                                                                    
                                                                    //Updates the participant 'joined' and 'status' attributes.
                                                                    let dicoAtt = [Constant.Participant.Attribute.status:Constant.Participant.Status.connected,
                                                                                   Constant.Participant.Attribute.joined:round(NSDate().timeIntervalSince1970)] as [String: Any]
                                                                    
                                                                    let newParticipantPath = participantPath + "/" +  userId!
                                                                    let wbcParticipant = WCWebcom(url: newParticipantPath)
                                                                    wbcParticipant?.update(dicoAtt as NSObject,
                                                                                           onComplete: { errorUpdate in
                                                                                            completeCallback(errorUpdate)
                                                                    })
                                                                    
                                                                    return
                                                                }
                                                                
                                                                completeCallback(errUpdt)
                                                            })
                                                        } else {
                                                            completeCallback(AppError.createError("The invitation id is nil."))
                                                        }
                                                    } else {
                                                        completeCallback(AppError.createError("check the structure of your 'participants' model in the database."))
                                                    }
                                                    break
                                                }
                                            }
                                        } else {
                                            completeCallback(AppError.createError("check the structure of your 'participants' model in the database."))
                                        }
        })
        
        //Updates the 'status' to WAS_CONNECTED in case of disconnection.
        let pathOnDisconnect = participantPath + "/" +  userId!
        let wbcParticipant = WCWebcom(url: pathOnDisconnect)
        
        let wbcParticipantDisconnect = wbcParticipant?.onDisconnect
        let dicoOndisconnect = [Constant.Participant.Attribute.status: Constant.Participant.Status.wasConnected]
        
        wbcParticipantDisconnect?.update(dicoOndisconnect as NSObject)
    }
    
    
    /**
     Leaves the room this method is applied to.
     When fired, it sets the connected status of the current participant to WAS_CONNECTED.
     
     - Parameters:
        - completeCallback: Block called once the action has been registered. On failure, the first argument contains the details of the error.
     */
    public func leave(completeCallback:@escaping(_ error: Error?) -> Void) {
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            completeCallback(AppError.createError("Your id is unknown in the database."))
            return
        }
        
        guard let _ =  uid else {
            completeCallback(AppError.createError("Room id is unknown in the database."))
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms + "/" + uid! + "/" + Constant.SuffixPath.participants
        
        let wbcParticipants = WCWebcom(url: participantPath)
        wbcParticipants?.onceEventType(.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            completeCallback(AppError.createError("Unknown participant id in the database."))
                                            return
                                        }
                                        
                                        if let participants = (data!.value as? [String: Any?]) {
                                            
                                            for (key, value) in participants {
                                                if (key == userId!) {
                                                    
                                                    if let participant = (value as? [String: Any?]) {
                                                        if (participant[Constant.Participant.Attribute.origin] as! String) != "" {
                                                            
                                                            let dicoAtt = [Constant.Participant.Attribute.status:Constant.Participant.Status.wasConnected]
                                                            
                                                            participantPath +=  "/" + userId!
                                                            
                                                            let wbcPartUpdt = WCWebcom(url: participantPath)
                                                            wbcPartUpdt?.update(dicoAtt as NSObject,
                                                                                onComplete: { errorUpdate in
                                                                                    
                                                                                    WATManager.sharedInstance.webcomParticipantPath = nil
                                                                                    completeCallback(errorUpdate)
                                                            })
                                                            break
                                                        } else {
                                                            completeCallback(AppError.createError("The invitation id is nil."))
                                                        }
                                                        
                                                    } else {
                                                        completeCallback(AppError.createError("Check the structure of your 'participant' model in the database."))
                                                    }
                                                }
                                            }
                                        } else {
                                            completeCallback(AppError.createError("Check the structure of your 'participants' model in the database."))
                                        }
        })
    }

    
    
//    MARK: - INFORMATION
    /**
     Gets all the messages of the room.
     
     - Parameters:
        - completeCallback: Block called once the information is obtained. On failure, the first argument contains the details of the error while the second one reports the array containing the room messages.
     */
    public func messages(completeCallback:@escaping(_ error: Error?, _ info: [WATMessage?]) -> Void) {
        
        guard let _ = WATManager.sharedInstance.base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), [nil])
            return
        }
        
        guard let _ = uid else {
            completeCallback(AppError.createError("Your room id is unknown in the database."), [nil])
            return
        }
        
        var messagePath = (WATManager.sharedInstance.base?.root?.toString())! as String
        messagePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        messagePath += "/" + uid! + "/" + Constant.SuffixPath.messages
        
        let wbcMessages = WCWebcom(url: messagePath)
        wbcMessages?.onceEventType(.value,
                                   withCallback: { (data, str) in
                                    
                                    guard let _ = data?.value else {
                                        completeCallback(AppError.createError("No message in the database."), [nil])
                                        return
                                    }
                                    if let messages = (data!.value as? [String: Any?]) {
                                        
                                        var tab = [WATMessage?]()
                                        
                                        for (_, value) in messages {
                                            if let message = value as? [String: Any?] {
                                                
                                                let messageObject = WATMessage.init(from: message[Constant.Message.Attribute.from] as! String,
                                                                                    roomId: message[Constant.Message.Attribute.roomId] as! String,
                                                                                    text: message[Constant.Message.Attribute.text] as! String,
                                                                                    uid: message[Constant.Message.Attribute.uid] as! String,
                                                                                    created: message[Constant.Message.Attribute.created] as! Double)
                                                
                                                tab.append(messageObject)
                                                
                                            } else {
                                                completeCallback(AppError.createError("check the structure of your 'messages' model in the database."), [nil])
                                            }
                                        }
                                        completeCallback(nil, tab)
                                    } else {
                                        completeCallback(AppError.createError("check the structure of your 'messages' model in the database."), [nil])
                                    }
        })
    }
    
    
    /**
     Gets all the participants of the room.
     
     - Parameters:
        - completeCallback: Block called once the information is obtained. On failure, the first argument contains the details of the error while the second one reports the array containing the room participants.
     */
    public func participants(completeCallback:@escaping(_ error: Error?, _ info: [WATParticipant?]) -> Void) {
        
        guard let _ = WATManager.sharedInstance.base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), [nil])
            return
        }
        
        guard let _ = uid else {
            completeCallback(AppError.createError("Your room id is unknown in the database."), [nil])
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        participantPath += "/" + uid! + "/" + Constant.SuffixPath.participants
        
        let wbcParticipants = WCWebcom(url: participantPath)
        wbcParticipants?.onceEventType(.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            completeCallback(AppError.createError("No participant in the database."), [nil])
                                            return
                                        }
                                        
                                        if let participants = (data!.value as? [String: Any?]) {
                                            
                                            var tab = [WATParticipant?]()
                                            
                                            for (_, value) in participants {
                                                if let participant = value as? [String: Any?] {
                                                    
                                                    let participantObject = WATParticipant.init(role: participant[Constant.Participant.Attribute.role] as! String,
                                                                                                status: participant[Constant.Participant.Attribute.status] as! String,
                                                                                                joined: participant[Constant.Participant.Attribute.joined] as! Double,
                                                                                                origin: participant[Constant.Participant.Attribute.origin] as! String)
                                                    
                                                    tab.append(participantObject)
                                                    
                                                } else {
                                                    completeCallback(AppError.createError("check the structure of your 'participants' model in the database."), [nil])
                                                }
                                            }
                                            completeCallback(nil, tab)
                                        } else {
                                            completeCallback(AppError.createError("check the structure of your 'participants' model in the database."), [nil])
                                        }
        })
    }

    
//    MARK: - LISTENERS
    /**
     Observes the last message text in the room.
     
     - Parameters:
        - completeCallback: Block called once a new message arrives. On failure, the first argument contains the details of the error while the second one contains only the message text and not the message instance.
     */
    public func onLastMsg(completeCallback:@escaping(_ error: Error?, _ info: String?) -> Void) {
        
        DLog("-oOo-  LISTENING TO THE LAST MESSAGE  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        guard let _ =  uid else {
            completeCallback(AppError.createError("Room id is unknown in the database."), nil)
            return
        }
        
        var metaPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        metaPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        metaPath += "/" + uid! + "/" + Constant.SuffixPath.meta + "/" + Constant.Meta.lastMsg
        
        let wbcMeta = WCWebcom(url: metaPath)
        wbcMeta?.onEventType(.value,
                             withCallback: { (data, str) in
                                
                                guard let _ = data?.value else {
                                    completeCallback(AppError.createError("Empty value in the database."), nil)
                                    return
                                }
                                
                                if let lastMsg = (data!.value as? String) {
                                    
                                    completeCallback(nil, lastMsg)
                                    
                                } else {
                                    completeCallback(AppError.createError("check the structure of your 'meta' model in the database."), nil)
                                }
        })
    }
    
    
    /**
     Observes new messages of the room.
     
     - Parameters:
        - completeCallback: Block called once a new message arrives. On failure, the first argument contains the details of the error while the second one contains the `WATMessage` itself.
     */
    public func onNewMessage(completeCallback:@escaping(_ error: Error?, _ info: WATMessage?) -> Void) {
        
        DLog("-oOo-  LISTENING TO NEW MESSAGES  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        guard let _ =  uid else {
            completeCallback(AppError.createError("Room id is unknown in the database."), nil)
            return
        }
        
        var messagePath = (WATManager.sharedInstance.base?.root?.toString())! as String
        messagePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        messagePath += "/" + uid! + "/" + Constant.SuffixPath.messages
        
        let wbcMessages = WCWebcom(url: messagePath)
        wbcMessages?.onEventType(.childAdded,
                                 withCallback: { (data, str) in
                                    
                                    guard let _ = data?.value else {
                                        completeCallback(AppError.createError("Empty child added in the database."), nil)
                                        return
                                    }
                                    
                                    if let messages = (data!.value as? [String: Any?]) {
                                        
                                        let messageObject = WATMessage.init(from: messages[Constant.Message.Attribute.from] as! String,
                                                                            roomId: messages[Constant.Message.Attribute.roomId] as! String,
                                                                            text: messages[Constant.Message.Attribute.text] as! String,
                                                                            uid: messages[Constant.Message.Attribute.uid] as! String,
                                                                            created: messages[Constant.Message.Attribute.created] as! Double)
                                        completeCallback(nil, messageObject)
                                        
                                    } else {
                                        completeCallback(AppError.createError("check the structure of your 'invites' model in the database."), nil)
                                    }
        })
    }
    
    
    /**
     Observes the participant status modification in this room.
     
     - Parameters:
        - completeCallback: Block called once the status of a participant has changed. On failure, the first argument contains the details of the error while the second one contains the concerned `WATParticipant`.
     */
    public func onParticipantStatusChanged(completeCallback:@escaping(_ error: Error?, _ info: WATParticipant?) -> Void) {
        
        DLog("-oOo-  LISTENING TO PARTICIPANTS STATUS CHANGES  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        guard let _ =  uid else {
            completeCallback(AppError.createError("Room id is unknown in the database."), nil)
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        participantPath += "/" + uid! + "/" + Constant.SuffixPath.participants
        
        let wbcParticipants = WCWebcom(url: participantPath)
        
        wbcParticipants?.onceEventType(.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            return
                                        }
                                        
                                        if let participants = (data!.value as? [String: Any?]) {
                                            
                                            for (key, value) in participants {
                                                
                                                if let participant = (value as? [String: Any?]) {
                                                    
                                                    let pth = participantPath + "/" + key + "/" + Constant.Participant.Attribute.status
                                                    let wbcParticipantStatus = WCWebcom(url: pth)
                                                    wbcParticipantStatus?.onEventType(.value,
                                                                                      withCallback: { (dataStatus, strStatus) in
                                                                                        
                                                                                        let participantObject = WATParticipant.init(role: participant[Constant.Participant.Attribute.role] as! String,
                                                                                                                                    status: dataStatus!.value as! String,
                                                                                                                                    joined: participant[Constant.Participant.Attribute.joined] as! Double,
                                                                                                                                    origin: participant[Constant.Participant.Attribute.origin] as! String)
                                                                                        
                                                                                        completeCallback(nil, participantObject)
                                                    })
                                                } else {
                                                    completeCallback(AppError.createError("Check the structure of your 'participant' model in the database."), nil)
                                                }
                                            }
                                        } else {
                                            completeCallback(AppError.createError("Check the structure of your 'participant' model in the database."), nil)
                                        }
        })
    }
    
    
    /**
     Removes observer for the last message text in the room.
     */
    public func offLastMsg(){
        
        DLog("-oOo-  STOP LISTENING TO THE LAST MESSAGE  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId, let _ =  uid else {
            return
        }
        
        var metaPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        metaPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        metaPath += "/" + uid! + "/" + Constant.SuffixPath.meta + "/" + Constant.Meta.lastMsg
        
        let wbcMeta = WCWebcom(url: metaPath)
        wbcMeta?.offEventType(.value)
    }
    
    
    /**
     Removes observer for new messages of the room.
     */
    public func offNewMessage() {
        
        DLog("-oOo-  STOP LISTENING TO NEW MESSAGES  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        
        guard let _ =  userId, let _ =  uid else {
            return
        }
        
        var messagePath = (WATManager.sharedInstance.base?.root?.toString())! as String
        messagePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        messagePath += "/" + uid! + "/" + Constant.SuffixPath.messages
        
        let wbcMessages = WCWebcom(url: messagePath)
        wbcMessages?.offEventType(.childAdded)
    }

    
    /**
     Removes observer for the participant status modification in this room.
     */
    public func offParticipantStatusChanged() {
        
        DLog("-oOo-  STOP LISTENING TO PARTICIPANTS STATUS CHANGES  -oOo-")
        
        let userId = WATManager.sharedInstance.current?.uid
        guard let _ =  userId else {
            return
        }
        
        guard let _ =  uid else {
            return
        }
        
        var participantPath = (WATManager.sharedInstance.base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        participantPath += "/" + uid! + "/" + Constant.SuffixPath.participants
        
        let wbcParticipants = WCWebcom(url: participantPath)
        
        wbcParticipants?.onceEventType(.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            return
                                        }
                                        
                                        if let participants = (data!.value as? [String: Any?]) {
                                            
                                            for (key, _) in participants {
                                                
                                                let pth = participantPath + "/" + key + "/" + Constant.Participant.Attribute.status
                                                let wbcParticipantStatus = WCWebcom(url: pth)
                                                wbcParticipantStatus?.offEventType(.value)
                                            }
                                        }
        })
    }
 
    
//    MARK: - PRIVATE HELPERS
    internal class func createObjectFrom(_ dicoObject: [String : Any?]) -> WATRoom {
        
        let newRoom =  WATRoom.init(name: dicoObject[Constant.Room.Attribute.name] as! String,
                                    owner: dicoObject[Constant.Room.Attribute.owner] as! String,
                                    status: dicoObject[Constant.Room.Attribute.status] as! String,
                                    _public: dicoObject[Constant.Room.Attribute.publik] as! Bool,
                                    _created: dicoObject[Constant.Room.Attribute.created] as! Double,
                                    _closed: dicoObject[Constant.Room.Attribute.closed] as? Double)
        
        newRoom.uid = dicoObject[Constant.Room.Attribute.uid] as! String?
        
        return newRoom
    }
    
    internal class func createDicoRoom(_ name: String, as publik: Bool, withKey key: String) -> [String : Any?] {
        
        return [Constant.Room.Attribute.name:name,
                Constant.Room.Attribute.owner:WATManager.sharedInstance.current!.uid!,
                Constant.Room.Attribute.status:Constant.Room.Status.opened,
                Constant.Room.Attribute.publik:publik,
                Constant.Room.Attribute.created:round(NSDate().timeIntervalSince1970),
                Constant.Room.Attribute.uid:key,
                Constant.Room.Attribute.closed:0.0]
        as [String : Any?]
    }
    
    internal class func createMetaFrom(_ dicoObject: [String : Any?]) -> [String : Any] {
        
        return [Constant.Room.Attribute.name:dicoObject[Constant.Room.Attribute.name] as! String,
                Constant.Room.Attribute.owner:dicoObject[Constant.Room.Attribute.owner] as! String,
                Constant.Room.Attribute.publik:dicoObject[Constant.Room.Attribute.publik] as! Bool] as [String : Any]
    }
}
