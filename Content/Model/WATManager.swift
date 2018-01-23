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


//Function used to print only in DEBUG MODE.
func DLog(_ item: @autoclosure () -> Any,
          separator: String = " ",
          terminator: String = "\n") {

    #if DEBUG
        Swift.print(item(),
                    separator:separator,
                    terminator: terminator)
    #endif
}


// Used to pass an incoming parameter for the singleton creation.
private class SingletonHelper {
    var param:String?
}


/**
 Class to be used to create communication between the local application and the `Webcom` server.
 */
public class WATManager {

//    MARK: - INITIALISATION
    ///The `Webcom` instance of the `WATManager` singleton.
    public private(set) var base: WCWebcom?
    
    ///The `WATUser` instance of the `WATManager` singleton dealing with the current authenticated user.
    public private(set) var current: WATUser?
    
    internal var webcomParticipantPath: String? //Enables update of the participant status in case of dis/connection.
    private var webcomUserPath: String? //Enables update of the user status in case of dis/connection.
    
    private typealias wsConnectStatus = (status: Bool, date: Double)
    private var wsConnect: (in: wsConnectStatus, out: wsConnectStatus)
    
    private static let setup = SingletonHelper()
    
    ///The `WATManager` singleton.
    public static let sharedInstance = WATManager()
    //To be used with 'private init()'.
    
    /**
     Function to be called the first time you want to create the `WATManager` instance.
     - Parameter URL: The namespace location on the webcom server.
     - Returns: A `WATManager` singleton.
     */
    public class func connectAt(_ URL:String) -> WATManager {
        WATManager.setup.param = URL
        return WATManager.sharedInstance
    }
    
    
    private init() {
        
        let webcomURL = WATManager.setup.param
        guard let _ = webcomURL else {
            fatalError("E.R.R.O.R. : never call the 'sharedInstance' if you haven't used the 'connectAt' initializer before.")
        }
        
        if (webcomURL != "") {
        
            DLog("Connect WEBCOM")
            base = WCWebcom(url: webcomURL!)
            
            wsConnect.in = (false, 0.0)
            wsConnect.out = (false, 0.0)
            self.wsConnection() //Listener to the websocket connection.
            
        } else {
            fatalError("E.R.R.O.R. : your URL isn't valid.")
        }
    }

//    MARK: - AUTHENTICATION
    /**
     Authentication notifier fired when the authentication status of the user has changed.
     
     - Parameters:
        - completeCallback: Block called once authentication status has changed. On failure, the first argument contains the details of the error while the second one confirms/denies (true/false) the authentication status.
     */
    public func authStatus(completeCallback:@escaping(_ error: Error?,_ status: Bool) -> Void) {
        
        DLog("-oOo-  Resume  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), false)
            return
        }
        
        self.base?.resume(callback: { (errorRes, infoRes) in
            
            let statusOn = ((infoRes != nil) ? true : false)
            completeCallback(errorRes, statusOn)
        })
    }

    
    /**
     Authentication supported by an incoming token provided by the Webcom server.
     
     - Parameters:
        - token: Name of the provider as described in the oAuth2 authentication Flexible Datasync documentation.
        - msisdn: Phone number of the user who wants to be authenticated.
        - completeCallback: Block called once authentication is complete. On failure, the first argument contains the details of the error while the second one contains information about the authenticated user.
     */
    public func authWith(token tok: String?,
                         msisdn phoneNumber: String!,
                         completeCallback:@escaping(_ error: Error?, _ info: WATUser?) -> Void) {
        
        DLog("-oOo-  Authentication with Token  -oOo-")
        
        guard let _ = base else {
            completeCallback(AppError.createError("Webcom instance is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = tok else {
            completeCallback(AppError.createError("Check your token that may be inappropriate."), nil)
            return
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateParticipantStatus),
                                               name: Notification.Name(Constant.connectionOK),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateUserStatus),
                                               name: Notification.Name(Constant.connectionOK),
                                               object: nil)
        
        base?.auth(withToken: tok!,
                   onComplete: {(error, info) in
                    
                    guard let _ = error else {
                        
                        var msisdnPath = (self.base?.root?.toString())! as String
                        msisdnPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.msisdn + "/" + phoneNumber
                        
                        let wbcMsisdns = WCWebcom(url: msisdnPath)
                        
                        wbcMsisdns?.onceEventType(WCEventType.value,
                                                  withCallback: { (data, str) in
                                                    
                                                    guard let _ = data?.value else {
                                                        guard let _ = info?.uid else {
                                                            completeCallback(AppError.createError("Authentication uid is nil ... check this !"), nil)
                                                            return
                                                        }
                                                        
                                                        self.createUser(name: "newUser",
                                                                        msisdn: phoneNumber,
                                                                        uid: info?.uid,
                                                                        complete: { (error, user) in
                                                                            
                                                                            self.current = user
                                                                            var userPath = (self.base?.root?.toString())! as String
                                                                            userPath += "/" + Constant.SuffixPath.users + "/" + (user?.uid)!
                                                                            self.webcomUserPath = userPath
                                                                            
                                                                            let wbcUsers = WCWebcom(url: userPath)
                                                                            
                                                                            let wbcUserDisconnect = wbcUsers?.onDisconnect
                                                                            let dicoOndisconnect = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
                                                                            wbcUserDisconnect?.update(dicoOndisconnect as NSObject)
                                                                            
                                                                            completeCallback(error, user)
                                                        })
                                                        return
                                                    }
                                                    
                                                    let userId = data!.value as! String
                                                    var userPath = (self.base?.root?.toString())! as String
                                                    userPath += "/" + Constant.SuffixPath.users + "/" + userId
                                                    self.webcomUserPath = userPath
                                                    
                                                    let wbcUsers = WCWebcom(url: userPath)
                                                    
                                                    let wbcUserDisconnect = wbcUsers?.onDisconnect
                                                    let dicoOndisconnect = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
                                                    wbcUserDisconnect?.update(dicoOndisconnect as NSObject)
                                                    
                                                    wbcUsers?.onceEventType(WCEventType.value,
                                                                            withCallback: { (data, str) in
                                                                                
                                                                                let user = data?.exportVal() as? [String:Any?]
                                                                                
                                                                                guard let _ = user else {
                                                                                    completeCallback(AppError.createError("User info is nil... check your database."), nil)
                                                                                    return
                                                                                }
                                                                                
                                                                                if ((user![Constant.User.Attribute.status] as! String) == Constant.User.Status.disconnected) {
                                                                                    
                                                                                    let dico = [Constant.User.Attribute.status: Constant.User.Status.connected,
                                                                                                Constant.User.Attribute.lastSeen: round(NSDate().timeIntervalSince1970)] as [String: Any]
                                                                                    
                                                                                    wbcUsers?.update(dico as NSObject,
                                                                                                     onComplete: { (errUpdt) in
                                                                                                        
                                                                                                        guard let _ = errUpdt else {
                                                                                                            
                                                                                                            let userInfo = WATUser.init(name: user![Constant.User.Attribute.name] as! String,
                                                                                                                                        status: Constant.User.Status.connected,
                                                                                                                                        lastSeen: round(NSDate().timeIntervalSince1970),
                                                                                                                                        msisdn: user![Constant.User.Attribute.msisdn] as! String)
                                                                                                            //
                                                                                                            userInfo.uid = userId
                                                                                                            self.current = userInfo
                                                                                                            completeCallback(nil, userInfo)
                                                                                                            return
                                                                                                        }
                                                                                                        
                                                                                                        completeCallback(errUpdt, nil)
                                                                                    })
                                                                                } else {
                                                                                    
                                                                                    let userInfo = WATUser.init(name: user![Constant.User.Attribute.name] as! String,
                                                                                                                status: user![Constant.User.Attribute.status] as! String,
                                                                                                                lastSeen: round(NSDate().timeIntervalSince1970),
                                                                                                                msisdn: user![Constant.User.Attribute.msisdn] as! String)
                                                                                    
                                                                                    userInfo.uid = userId
                                                                                    self.current = userInfo
                                                                                    completeCallback(nil, userInfo)
                                                                                }
                                                    })
                        })
                        return
                    }
                    
                    completeCallback(error, nil)})
    }
    
    
    /**
     Logouts the currently authenticated user.
     
     - Parameters:
        - completeCallback: Block called once authentication has been removed from the server. On failure, the argument contains the details of the error.
     */
    public func logout(completeCallback:@escaping(_ error: Error?) -> Void) {
        
        DLog("-oOo-  Logout  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."))
            return
        }
        
        guard let _ = current?.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."))
            return
        }
        
        WATManager.sharedInstance.offInviteAdded()
        
        // Updates USER STATUS and logout on completion.
        var userPath = (self.base?.root?.toString())! as String
        userPath += "/" + Constant.SuffixPath.users + "/" + (current?.uid)!
        
        let wbcUsers = WCWebcom(url: userPath)
        wbcUsers?.onceEventType(WCEventType.value,
                                withCallback: { (data, str) in
                                    
                                    let user = data?.exportVal() as? [String:Any?]
                                    
                                    guard let _ = user else {
                                        completeCallback(AppError.createError("User info is nil... status update and logout are impossible."))
                                        return
                                    }
                                    
                                    let dico = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
                                    
                                    wbcUsers?.update(dico as NSObject,
                                                     onComplete: { (errUpdt) in
                                                        
                                                        guard let _ = errUpdt else {
                                                            
                                                            self.base?.logout(callback: { errLogout in
                                                                completeCallback(errLogout)
                                                            })
                                                            return
                                                        }
                                                        completeCallback(AppError.createError("LOGOUT impossible."))
                                    })
        })
    }
    
    
    /**
     Authentication according to the oAuth2 protocol.
     
     - Parameters:
        - providerName: Name of the provider as described in the oAuth2 authentication Flexible Datasync documentation.
        - msisdn: Phone number of the user who wants to be authenticated.
        - completeCallback: Block called once authentication is complete. On failure, the first argument contains the details of the error while the second one contains information about the authenticated user.
        - cancelCallback: Block called once the user clicked on the 'cancel' button during the authentication process.
     */
    public func oAuth2With(_ providerName: String!,
                           msisdn phoneNumber: String!,
                           completeCallback:@escaping(_ error: Error?, _ info: WATUser?) -> Void,
                           cancelCallback:@escaping(_ error: Error) -> Void) {
        
        DLog("-oOo-  oAuth2 authentication  -oOo-")
        
        guard let _ = base else {
            completeCallback(AppError.createError("Webcom instance is nil. Check the URL."), nil)
            return
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateParticipantStatus),
                                               name: Notification.Name(Constant.connectionOK),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateUserStatus),
                                               name: Notification.Name(Constant.connectionOK),
                                               object: nil)
        
        
        base?.oAuth2Provider(providerName,
                             onComplete: {(error, info) in
                                
                                guard let _ = error else {
                                    
                                    var msisdnPath = (self.base?.root?.toString())! as String
                                    msisdnPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.msisdn + "/" + phoneNumber
                                    
                                    let wbcMsisdns = WCWebcom(url: msisdnPath)
                                    
                                    wbcMsisdns?.onceEventType(.value,
                                                              withCallback: { (data, str) in
                                                                
                                                                guard let _ = data?.value else {
                                                                    guard let _ = info?.uid else {
                                                                        completeCallback(AppError.createError("Authentication uid is nil ... check this !"), nil)
                                                                        return
                                                                    }
                                                                    
                                                                    self.createUser(name: info?.userDisplayName,
                                                                                    msisdn: phoneNumber,
                                                                                    uid: info?.uid,
                                                                                    complete: { (error, user) in
                                                                                        
                                                                                        self.current = user
                                                                                        var userPath = (self.base?.root?.toString())! as String
                                                                                        userPath += "/" + Constant.SuffixPath.users + "/" + (info?.uid)!
                                                                                        self.webcomUserPath = userPath
                                                                                        
                                                                                        let wbcUsers = WCWebcom(url: userPath)
                                                                                        
                                                                                        let wbcUserDisconnect = wbcUsers?.onDisconnect
                                                                                        let dicoOndisconnect = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
                                                                                        wbcUserDisconnect?.update(dicoOndisconnect as NSObject)
                                                                                        
                                                                                        completeCallback(error, user)
                                                                    })
                                                                    return
                                                                }
                                                                
                                                                let userId = data!.value as! String
                                                                var userPath = (self.base?.root?.toString())! as String
                                                                userPath += "/" + Constant.SuffixPath.users + "/" + userId
                                                                self.webcomUserPath = userPath
                                                                
                                                                let wbcUsers = WCWebcom(url: userPath)
                                                                
                                                                let wbcUserDisconnect = wbcUsers?.onDisconnect
                                                                let dicoOndisconnect = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
                                                                wbcUserDisconnect?.update(dicoOndisconnect as NSObject)
                                                                
                                                                wbcUsers?.onceEventType(.value,
                                                                                        withCallback: { (data, str) in
                                                                                            
                                                                                            let user = data?.exportVal() as? [String:Any?]
                                                                                            
                                                                                            guard let _ = user else {
                                                                                                completeCallback(AppError.createError("User info is nil... check your database."), nil)
                                                                                                return
                                                                                            }
                                                                                            
                                                                                            if ((user![Constant.User.Attribute.status] as! String) == Constant.User.Status.disconnected) {
                                                                                                
                                                                                                let dico = [Constant.User.Attribute.status: Constant.User.Status.connected,
                                                                                                            Constant.User.Attribute.lastSeen: round(NSDate().timeIntervalSince1970)] as [String: Any]
                                                                                                
                                                                                                wbcUsers?.update(dico as NSObject,
                                                                                                                 onComplete: { (errUpdt) in
                                                                                                                    
                                                                                                                    guard let _ = errUpdt else {
                                                                                                                        
                                                                                                                        let userInfo = WATUser.init(name: user![Constant.User.Attribute.name] as! String,
                                                                                                                                                    status: Constant.User.Status.connected,
                                                                                                                                                    lastSeen: round(NSDate().timeIntervalSince1970),
                                                                                                                                                    msisdn: user![Constant.User.Attribute.msisdn] as! String)
                                                                                                                        
                                                                                                                        userInfo.uid = userId
                                                                                                                        self.current = userInfo
                                                                                                                        completeCallback(nil, userInfo)
                                                                                                                        return
                                                                                                                    }
                                                                                                                    
                                                                                                                    completeCallback(errUpdt, nil)
                                                                                                })
                                                                                            } else {
                                                                                                
                                                                                                let userInfo = WATUser.init(name: user![Constant.User.Attribute.name] as! String,
                                                                                                                            status: user![Constant.User.Attribute.status] as! String,
                                                                                                                            lastSeen: round(NSDate().timeIntervalSince1970),
                                                                                                                            msisdn: user![Constant.User.Attribute.msisdn] as! String)
                                                                                                
                                                                                                userInfo.uid = userId
                                                                                                self.current = userInfo
                                                                                                completeCallback(nil, userInfo)
                                                                                            }
                                                                })
                                    })
                                    return
                                }
                                
                                completeCallback(error, nil)
        },
                             onCancel: {error in
                                cancelCallback(error)
        })
    }
    
    
//    MARK: - INFORMATION
    /**
     Gets the `WATRoom` identified by its unique identifier provided by the server.
     
     - Parameters:
        - uid: Room identifier provided by the Webcom server.
        - completeCallback: Block called once the room information returns. On failure, the first argument contains the details of the error while the second one contains information about the room itself.
     */
    public func getRoom(uid: String,
                        completeCallback:@escaping(_ error: Error?, _ info: WATRoom?) -> Void) {
        
        DLog("-oOo-  Room  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = current else {
            completeCallback(AppError.createError("No user defined in the base for the authenticated person."), nil)
            return
        }
        
        var roomPath = (base?.root?.toString())! as String
        roomPath += "/" + Constant.SuffixPath.rooms + "/" + uid
        
        let wbcRooms = WCWebcom(url: roomPath)
        
        guard let _ = current!.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        wbcRooms?.onceEventType(WCEventType.value,
                               withCallback: { (data, str) in
                                
                                guard let _ = data?.value else {
                                    
                                    completeCallback(AppError.createError("No room info with this id."), nil)
                                    return
                                }
                                
                                let room = data!.value as? [String:Any?]
                                let roomInfo = WATRoom.init(name: room![Constant.Room.Attribute.name] as! String,
                                                            owner: room![Constant.Room.Attribute.owner] as! String,
                                                            status: room![Constant.Room.Attribute.status] as! String,
                                                            _public: room![Constant.Room.Attribute.publik] as! Bool,
                                                            _created: room![Constant.Room.Attribute.created] as!Double,
                                                            _closed: room![Constant.Room.Attribute.closed] as? Double)
                                roomInfo.uid = uid
                                
                                completeCallback(nil, roomInfo)
        })
    }
   
    
    /**
     Gets the `WATUser` identified by his phone number registered on the Webcom server.
     
     - Parameters:
        - phoneNumber: Phone number of the user.
        - completeCallback: Block called once the user information returns. On failure, the first argument contains the details of the error while the second one contains information about the user itself.
     */
    public func getUser(phoneNumber: String,
                        completeCallback:@escaping(_ error: Error?, _ info: WATUser?) -> Void) {
        
        DLog("-oOo-  Get User  -oOo-")
        
        self.getUserIdFrom(msisdn: phoneNumber) { (errorUid, userId) in
            
            guard let _ = errorUid else {
                
                var userPath = (self.base?.root?.toString())! as String
                userPath += "/" + Constant.SuffixPath.users + "/" + userId!
                
                let wbcUser = WCWebcom(url: userPath)
                
                wbcUser?.onceEventType(WCEventType.value,
                                       withCallback: { (data, str) in
                                        
                                        guard let _ = data?.value else {
                                            
                                            completeCallback(AppError.createError("Unregistered user in the database."), nil)
                                            return
                                        }
                                        
                                        let user = data!.value as? [String:Any?]
                                        let userInfo = WATUser.init(name: user![Constant.User.Attribute.name] as! String,
                                                                    status: user![Constant.User.Attribute.status] as! String,
                                                                    lastSeen: user![Constant.User.Attribute.lastSeen] as! Double,
                                                                    msisdn: user![Constant.User.Attribute.msisdn] as! String)
//                                        ,
//                                                                    email: user![Constant.User.Attribute.email] as! String)
                                        
                                        guard let _ = user![Constant.User.Attribute.uid] else {
                                            
                                            completeCallback(AppError.createError("Nil user id in the database."), nil)
                                            return
                                        }
                                        
                                        userInfo.uid = (user![Constant.User.Attribute.uid] as! String)
                                        
                                        completeCallback(nil, userInfo)
                })
                return
            }
            
            completeCallback(errorUid!, nil)
        }
    }
  
    
    /**
     Gets all the invitations of the authenticated user.
     
     - Parameters:
         - completeCallback: Block called once the information returns. On failure, the first argument contains the details of the error while the second one reports the array containing the user invitations.
     */
    public func invites(completeCallback:@escaping(_ error: Error?, _ info: [WATInvite?]) -> Void) {
        
        DLog("-oOo-  Invites  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), [nil])
            return
        }
        
        guard let _ = current?.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."), [nil])
            return
        }
        
        var invitePath = (base?.root?.toString())! as String
        invitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites + "/" + (current?.uid)!
        
        let wbcInvites = WCWebcom(url: invitePath)
        wbcInvites?.onceEventType(WCEventType.value,
                                  withCallback: { (data, str) in
                      
                                    guard let _ = data?.value else {
                                        completeCallback(nil, [nil])
                                        return
                                    }
                                    
                                    if let invites = (data!.value as? [String: Any?]) {
                                        
                                        var tab = [WATInvite?]()
                                        
                                        for (_, value) in invites {
                                            if let invite = (value as? [String: Any?]) {
                                                let inviteObject = WATInvite.init(from: invite[Constant.Invite.Attribute.from] as! String,
                                                                                  room: invite[Constant.Invite.Attribute.room] as! String,
                                                                                  status: invite[Constant.Invite.Attribute.status] as! String,
                                                                                  topic: invite[Constant.Invite.Attribute.topic] as! String,
                                                                                  created: invite[Constant.Invite.Attribute.created] as! Double,
                                                                                  ended: invite[Constant.Invite.Attribute.ended] as? Double)
                                                
                                                tab.append(inviteObject)
                                            }
                                        }
                                        completeCallback(nil, tab)
                                        
                                    } else {
                                        completeCallback(AppError.createError("check the structure of your 'invites' model in the database."), [nil])
                                    }
        })
    }
  
    
    /**
     Removes observer for new invitations as regards the authenticated user.
     */
    public func offInviteAdded() {
        
        DLog("-oOo-  STOP LISTENING TO ADDED INVITE  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            return
        }
        
        guard let _ = current?.uid else {
            return
        }
        
        var invitePath = (base?.root?.toString())! as String
        invitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites + "/" + (current?.uid)!
        
        let wbcInvites = WCWebcom(url: invitePath)
        wbcInvites?.offEventType(.childAdded)
    }
    
    
    /**
     Observes new invitations for the authenticated user.
     
     - Parameters:
        - completeCallback: Block called once a new invitation is received. On failure, the argument contains the details of the error while the second one contains the new WATInvite object.
     */
    public func onInviteAdded(completeCallback:@escaping(_ error: Error?, _ object: WATInvite?) -> Void) {
        
        DLog("-oOo-  LISTENING TO ADDED INVITE  -oOo-")
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = current?.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        var invitePath = (base?.root?.toString())! as String
        invitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites + "/" + (current?.uid)!
        
        let wbcInvites = WCWebcom(url: invitePath)
        wbcInvites?.onEventType(.childAdded,
                                withCallback: { (data, str) in
                                    
                                    guard let _ = data?.value else {
                                        completeCallback(AppError.createError("Empty child added in the database."), nil)
                                        return
                                    }
                                    
                                    if let invites = (data!.value as? [String: Any?]) {
                                        
                                        if (invites[Constant.Invite.Attribute.status] as! String) == Constant.Invite.Status.ongoing {
                                            
                                            let inviteObject = WATInvite.init(from: invites[Constant.Invite.Attribute.from] as! String,
                                                                              room: invites[Constant.Invite.Attribute.room] as! String,
                                                                              status: invites[Constant.Invite.Attribute.status] as! String,
                                                                              topic: invites[Constant.Invite.Attribute.topic] as! String,
                                                                              created: invites[Constant.Invite.Attribute.created] as! Double,
                                                                              ended: invites[Constant.Invite.Attribute.ended] as? Double)
                                            completeCallback(nil, inviteObject)
                                        }
                                    } else {
                                        completeCallback(AppError.createError("check the structure of your 'invites' model in the database."), nil)
                                    }
        })
    }
    
    
    /**
     Gets the room created between the authenticated user and another one already registered on the Webcom server.
     
     - Parameters:
        - msisdn: Phone number of the user the room has been created with.
        - completeCallback: Block called once the room information returns. On failure, the first argument contains the details of the error while the second one contains information about the room itself.
     */
    public func roomWith(msisdn: String,
                         completeCallback:@escaping(_ error: Error?, _ rooms: WATRoom?) -> Void) {
        
        self.getUserIdFrom(msisdn: msisdn) { (errorId, userId) in
            
            guard let _ = errorId else {
                
                self.getRoomWith(self.current?.uid,
                                 and: userId,
                                 onComplete: { (errorRoom, room) in
                                    
                                    guard let _ = errorRoom else {
                                        completeCallback(nil, room)
                                        return
                                    }
                                    completeCallback(errorRoom, nil)
                })
                return
            }
            completeCallback(errorId, nil)
        }
    }
    
  
    
//    MARK: - MODIFICATION
    /**
     Changes the name of a registered user.
     
     - Parameters:
        - newName: New name of the user.
        - phoneNumber: Phone number of the user.
        - completeCallback: Block called once the message has been received. On failure, the argument contains the details of the error.
     */
    public func changeUserNameInto(newName: String!,
                                   for phoneNumber: String,
                                   completeCallback:@escaping(_ error: Error?) -> Void) {
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."))
            return
        }
        var msisdnPath = (self.base?.root?.toString())! as String
        msisdnPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.msisdn + "/" + phoneNumber
        
        let wbcMsisdns = WCWebcom(url: msisdnPath)
        
        wbcMsisdns?.onceEventType(WCEventType.value,
                                  withCallback: { (data, str) in
                                    
                                    guard let _ = data?.value else {
                                        completeCallback(AppError.createError("Unregistered user."))
                                        return
                                    }
                                    
                                    var userPath = (self.base?.root?.toString())! as String
                                    userPath += "/" + Constant.SuffixPath.users + "/" + (data!.value as! String)
                                    
                                    let wbcUsers = WCWebcom(url: userPath)
                                    let updatedName = [Constant.User.Attribute.name:newName]
                                    wbcUsers?.update(updatedName as NSObject,
                                                     onComplete: { (error) in
                                                        completeCallback(error)
                                    })
        })
    }
 
    
    /**
     Creates a room between the authenticated user and another one already registered on the Webcom server.
     
     - Parameters:
        - name: Name of the created room.
        - extra: Information to be put to characterize the room (not implemented yet).
        - publicRoom: Room status about its public access (false by default). The public representation isn't implemented yet.
        - phoneNumber: Phone number of the user the room must be created with.
        - completeCallback: Block called once the message has been received. On failure, the argument contains the details of the error while the second one contains information about the created room.
     */
    public func createRoom(name: String,
                           extra: Any?,
                           publicRoom: Bool,
                           with phoneNumber: String?,
                           completeCallback:@escaping(_ error: Error?, _ info: WATRoom?) -> Void) {
        
        DLog("-oOo-  Create Room  -oOo-")
        
        guard let _ = phoneNumber else {
            completeCallback(AppError.createError("Contact phone number mustn't be nil."), nil)
            return
        }
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = current, let _ = current?.uid else {
            completeCallback(AppError.createError("No user defined in the base for the authenticated person."), nil)
            return
        }
        
        self.getUserIdFrom(msisdn: phoneNumber!) { (error, userId) in
            
            guard let _ = error else {
                
                //Creation at the 'base'/rooms path
                var roomPath = (self.base?.root?.toString())! as String
                roomPath += "/" + Constant.SuffixPath.rooms
                
                let wbcRooms = WCWebcom(url: roomPath)
                
                guard let _ = self.current!.uid else {
                    completeCallback(AppError.createError("Your id is unknown in the database."), nil)
                    return
                }
                
                let dicoKey = ((self.current!.uid! < userId!) ? (self.current!.uid! + "_" + userId!) : (userId! + "_" + self.current!.uid!))
                
                let dicoRoom = WATRoom.createDicoRoom(name,
                                                      as: publicRoom,
                                                      withKey: dicoKey)
                let dico = [dicoKey:dicoRoom]
                wbcRooms?.update(dico as NSObject,
                                 onComplete: { errorDico in
                                    
                                    guard let _ = errorDico else {
                                        
                                        let room = WATRoom.createObjectFrom(dicoRoom)
                                        
                                        //Creation at the 'base'/_/rooms path
                                        var uRoomPath = (self.base?.root?.toString())! as String
                                        uRoomPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms + "/" + dicoKey
                                        
                                        let metaInfo = WATRoom.createMetaFrom(dicoRoom)
                                        let dicoURoom = [Constant.SuffixPath.meta:metaInfo]
                                        
                                        let wbcURoom = WCWebcom(url: uRoomPath)
                                        wbcURoom?.set(dicoURoom as NSObject?,
                                                      onComplete: { error in
                                                        
                                                        guard let _ = error else {
                                                            
                                                            self.createSelfInvite(roomId: dicoKey,
                                                                                  completeCallback: {errorInvt, inviteId in
                                                                                    
                                                                                    
                                                                                    guard let _ = inviteId else {
                                                                                        completeCallback(errorInvt, nil)
                                                                                        return
                                                                                    }
                                                                                    
                                                                                    guard let _ = errorInvt else {
                                                                                        
                                                                                        self.createSelfParticipantInRoom(dicoKey,
                                                                                                                         from: inviteId!,
                                                                                                                         completeCallback: {errorPart in
                                                                                                                            
                                                                                                                            guard let _ = errorPart else {
                                                                                                                                completeCallback(nil, room)
                                                                                                                                return
                                                                                                                            }
                                                                                                                            completeCallback(AppError.createError("self participation not created"), room)
                                                                                        })
                                                                                        return
                                                                                    }
                                                                                    
                                                                                    completeCallback(AppError.createError("{self invitation + self participation} not created"), nil)
                                                            })
                                                            
                                                            return
                                                        }
                                                        
                                                        completeCallback(AppError.createError("'meta' folder not created, 'roomId' not updated and {self invitation + self participation} not created"), nil)
                                        })
                                        
                                        return
                                    }
                                    
                                    completeCallback(errorDico, nil)
                })
                
                //                dispatchGroup.notify(queue: .main){}
                return
            }
            
            completeCallback(error, nil)
        }
    }
    
    
    /**
     Allows the authenticated user to send a message in a room.
     
     - Parameters:
        - text: Text to be sent in the message.
        - room: Room in which the message must be sent.
        - onComplete: Block called once the message has been received. On failure, the argument contains the details of the error.
     */
    public func sendMessage(_ text: String,
                            in room: WATRoom,
                            onComplete:@escaping(_ error: Error?) -> Void) {
        
        guard let _ = base?.root?.toString() else {
            onComplete(AppError.createError("Webcom base root is nil. Check the URL."))
            return
        }
        
        guard let _ = current?.uid else {
            onComplete(AppError.createError("Your id is unknown in the database."))
            return
        }
        
        let msg = WATMessage.init(from: (current?.uid)!,
                                  roomId: room.uid!,
                                  text: text)
        let msgObj = WATMessage.createObjectWith(msg)
        
        var globalPath = (base?.root?.toString())! as String
        globalPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms + "/" + room.uid!
        
        var messagePath =  globalPath + "/" + Constant.SuffixPath.messages
        let metaPath = globalPath + "/" + Constant.SuffixPath.meta
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        let wbcMessages = WCWebcom(url: messagePath)
        let wbcNewMsg = wbcMessages?.push(msgObj as NSObject?,
                                          onComplete: { (errorMsg) in
                                            
                                            guard let _ = errorMsg else {
                                                
                                                let wbcMeta = WCWebcom(url: metaPath)
                                                let dico = [Constant.Meta.lastMsg:text] as [String:String]
                                                
                                                wbcMeta?.update(dico as NSObject, onComplete: { errMeta in
                                                    onComplete(errMeta)
                                                    dispatchGroup.leave()
                                                })
                                                return
                                            }
                                            
                                            onComplete(errorMsg)
                                            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: .main){ //Updates 'uid' after confirmation of the object creation.
            
            guard let _ = wbcNewMsg?.name else {
                onComplete(AppError.createError("Id not created for this message."))
                return
            }
            
            messagePath += "/" + (wbcNewMsg?.name)!
            let uid = [Constant.Message.Attribute.uid:(wbcNewMsg?.name)!]
            let wbcMsgUpdate = WCWebcom.init(url: messagePath)
            wbcMsgUpdate?.update(uid as NSObject)
        }
    }



//    MARK: - PRIVATE HELPERS
    internal func changeStatusInvite(_ invite:WATInvite,
                                     to newStatus:String,
                                     completeCallback:@escaping(_ error: Error?) -> Void) {
        
        let dico = [Constant.Invite.Attribute.status:newStatus,
                    Constant.Invite.Attribute.topic:invite.topic]
        
        var invitePath = (WATManager.sharedInstance.base?.root?.toString())! as String
        invitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites + "/" + (WATManager.sharedInstance.current?.uid)! + "/" + invite.uid!
        
        let wbcInvite = WCWebcom(url: invitePath)
        wbcInvite?.update(dico as NSObject,
                          onComplete: { (errorUpdt) in
            completeCallback(errorUpdt)
        })
        
    }
    
    
    //Self invitation creation when a room is created.
    internal func createSelfInvite(roomId: String,
                                   completeCallback:@escaping(_ error: Error?, _ invitationId: String?) -> Void) {
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = current?.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        var invitePath = (base?.root?.toString())! as String
        invitePath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites
        invitePath += "/" + (current?.uid)!
        
        let wbcInvites = WCWebcom(url: invitePath)
        
        let dico = [Constant.Invite.Attribute.from:current?.uid,
                    Constant.Invite.Attribute.room:roomId,
                    Constant.Invite.Attribute.status:Constant.Invite.Status.accepted,
                    Constant.Invite.Attribute.topic:"Self invitation.",
                    Constant.Invite.Attribute.created:round(NSDate().timeIntervalSince1970),
                    Constant.Invite.Attribute.ended:0.0] as [String : Any?]
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        let wbcInvitesPush = wbcInvites?.push(dico as NSObject?,
                                              onComplete: { error in
                                                
                                                guard let _ = error else {
                                                    dispatchGroup.leave()
                                                    return
                                                }
                                                
                                                completeCallback(error, nil)
        })
        
        dispatchGroup.notify(queue: .main){
            
            guard let _ = wbcInvitesPush else {
                return
            }
            
            let valUpdate = wbcInvitesPush?.name ?? (String)(round(NSDate().timeIntervalSince1970))
            let updateDico = [Constant.Invite.Attribute.uid: valUpdate]
            
            let wbcInviteId = WCWebcom(url: invitePath + "/" + valUpdate)
            
            wbcInviteId?.update(updateDico as NSObject,
                              onComplete: { errorUpdt in
                                
                                completeCallback(errorUpdt, valUpdate)
            })
        }
    }
    
    
    //Self participant creation when a room is created.
    internal func createSelfParticipantInRoom(_ roomId: String,
                                              from invitationId: String,
                                              completeCallback:@escaping(_ error: Error?) -> Void) {
        
        guard let _ = base?.root?.toString() else {
            completeCallback(AppError.createError("Webcom base root is nil. Check the URL."))
            return
        }
        
        guard let _ = current?.uid else {
            completeCallback(AppError.createError("Your id is unknown in the database."))
            return
        }
        
        var participantPath = (base?.root?.toString())! as String
        participantPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.rooms
        participantPath += "/" + roomId + "/" + Constant.SuffixPath.participants + "/" + (current?.uid)!
        
        let wbcParticipants = WCWebcom(url: participantPath)
        
        let dico = [Constant.Participant.Attribute.role:Constant.Participant.Role.owner,
                    Constant.Participant.Attribute.status:Constant.Participant.Status.notConnected,
                    Constant.Participant.Attribute.joined:0.0,
                    Constant.Participant.Attribute.origin:invitationId] as [String : Any?]
        
        wbcParticipants?.set(dico as NSObject?,
                              onComplete: { error in
                                
                                guard let _ = error else {
                                    completeCallback(nil)
                                    return
                                }
                                
                                completeCallback(error)
        })
    }
    
    
    internal func createUser(name: String!,
                             msisdn: String!,
                             uid: String!,
                             complete:@escaping(_ error: Error?, _ info: WATUser?) -> Void) {
        
        var userPath = (base?.root?.toString())! as String
        userPath += "/" + Constant.SuffixPath.users
        
        let wbcUsers = WCWebcom(url: userPath)
        let lastDate: Double = round(NSDate().timeIntervalSince1970)
        
        let dicoBis = [Constant.User.Attribute.name:name,
                    Constant.User.Attribute.status:Constant.User.Status.connected,
                    Constant.User.Attribute.lastSeen:lastDate,
                    Constant.User.Attribute.msisdn:msisdn,
                    Constant.User.Attribute.uid:uid] as [String : Any]
        
        let dico = [uid:dicoBis] as [String : Any]
        
        let user = WATUser.init(name: dicoBis[Constant.User.Attribute.name] as! String,
                                status: dicoBis[Constant.User.Attribute.status] as! String,
                                lastSeen: dicoBis[Constant.User.Attribute.lastSeen] as! Double,
                                msisdn: dicoBis[Constant.User.Attribute.msisdn] as! String)
        user.uid = uid
        
        wbcUsers?.update(dico as NSObject,
                      onComplete: { errorPush in
                        
                        guard let _ = errorPush else {

                            //Creation at the 'base'/_/msisdn path
                            var msisdnPath = (self.base?.root?.toString())! as String
                            msisdnPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.msisdn
                            
                            let dicoMsisdn = [msisdn:uid] as [String:String]
                            
                            let wbcMsisdn = WCWebcom(url: msisdnPath)
                            wbcMsisdn?.update(dicoMsisdn as NSObject,
                                              onComplete: { error in
                                                
                                                complete(error, user)
                            })
                            
                            return
                        }
                        
                        complete(errorPush, user)
        })
    }


    //Returns the opened room with the specified userId (webcom uid).
    internal func getRoomWith(_ currentId: String?,
                              and userId: String?,
                              onComplete:@escaping(_ error: Error?, _ rooms: WATRoom?) -> Void) {
        
        guard let _ = currentId, let _ = userId else {
            onComplete(AppError.createError("Inappropriate ids values."), nil)
            return
        }
        
        let roomKey = ((currentId! < userId!) ? (currentId! + "_" + userId!) : (userId! + "_" + currentId!))
    
        var roomPath = (base?.root?.toString())! as String
        roomPath += "/" + Constant.SuffixPath.rooms + "/" + roomKey
        
        let wbcRoom = WCWebcom(url: roomPath)
        wbcRoom?.onceEventType(WCEventType.value,
                               withCallback: { (data, str) in
                                
                                guard let _ = data?.value else {
                                    onComplete(nil, nil)
                                    return
                                }
                                
                                let room = data!.value as! [String: Any?]
                                let tchatRoom = WATRoom.init(name: room[Constant.Room.Attribute.name] as! String,
                                                             owner: room[Constant.Room.Attribute.owner] as! String,
                                                             status: room[Constant.Room.Attribute.status] as! String,
                                                             _public: room[Constant.Room.Attribute.publik] as! Bool,
                                                             _created: room[Constant.Room.Attribute.created] as! Double,
                                                             _closed: room[Constant.Room.Attribute.closed] as? Double)
                                
                                tchatRoom.uid = room[Constant.Room.Attribute.uid] as? String
                                
                                onComplete(nil, tchatRoom)
        })
    }
    
    
    internal func getUserIdFrom(msisdn: String,
                                onComplete:@escaping(_ error: Error?, _ userId: String?) -> Void) {
        
        guard let _ = base?.root?.toString() else {
            onComplete(AppError.createError("Webcom base root is nil. Check the URL."), nil)
            return
        }
        
        guard let _ = current?.uid else {
            onComplete(AppError.createError("Your id is unknown in the database."), nil)
            return
        }
        
        var msisdnPath = (base?.root?.toString())! as String
        msisdnPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.msisdn
        
        let wbcMsisdns = WCWebcom(url: msisdnPath)
        wbcMsisdns?.onceEventType(WCEventType.value,
                                  withCallback: { (data, str) in
                                    
                                    guard let _ = data?.value else {
                                        
                                        onComplete(AppError.createError("Unregistered user in the database.\nCreate it and don't forget to send an invitation."), nil)
                                        return
                                    }
                                    
                                    let user = data!.exportVal() as? [String:Any?]
                                    
                                    guard let _ = user?[msisdn] as? String else {
                                        onComplete(AppError.createError("Unregistered user in the database.\nCreate it and don't forget to send an invitation."), nil)
                                        return
                                    }
                                    
                                    let userId = user![msisdn] as? String
                                    
                                    onComplete(nil, userId)
        })
    }
    
    
    //Updates the participant status when a reconnection occurs.
    @objc internal func updateParticipantStatus(notification: Notification) {
        
        guard let _ = webcomParticipantPath else {
            return
        }
        
        let path = webcomParticipantPath! + "/" + (current?.uid)!
        let wbcPart = WCWebcom(url: path)
        let wbcParticipantDisconnect = wbcPart?.onDisconnect
        let dicoOnDisconnect = [Constant.Participant.Attribute.status: Constant.Participant.Status.wasConnected]
        wbcParticipantDisconnect?.update(dicoOnDisconnect as NSObject)
        
        let wbcParticipant = WCWebcom(url: webcomParticipantPath!)
        wbcParticipant?.onceEventType(WCEventType.value,
                                      withCallback: { (data, str) in
                                        
                                        if let participants = (data!.value as? [String: Any?]) {

                                            for (key, value) in participants {
                                                if (key == self.current?.uid!) {
                                                    if let participant = value as? [String: Any?] {
                                                        if (participant[Constant.Participant.Attribute.origin] as! String) != "" {

                                                            //Updates the invitation to 'accepted' whatever the value.
                                                            let dico = [Constant.Invite.Attribute.status:Constant.Invite.Status.accepted]
                                                            let invitationId = participant[Constant.Participant.Attribute.origin] as! String

                                                            var invitationPath = (WATManager.sharedInstance.base?.root?.toString())! as String
                                                            invitationPath += "/" + Constant.SuffixPath.underscore + "/" + Constant.SuffixPath.invites
                                                            invitationPath += "/" + (WATManager.sharedInstance.current?.uid)! + "/" + invitationId

                                                            let wbcInvitations = WCWebcom(url: invitationPath)
                                                            wbcInvitations?.update(dico as NSObject)

                                                            //Updates the participant 'joined' (if time limit defined hereunder is OK) and 'status' attributes.
                                                            var dicoAtt = [Constant.Participant.Attribute.status:Constant.Participant.Status.connected] as [String: Any]
                                                            
                                                            let time = self.wsConnect.in.date - self.wsConnect.out.date
                                                            if (time > Constant.disconnectionTime) {
                                                                dicoAtt[Constant.Participant.Attribute.joined] = round(NSDate().timeIntervalSince1970)
                                                            }
                                                        
                                                            let newParticipantPath = self.webcomParticipantPath! + "/" +  (self.current?.uid)!
                                                            let wbcParticipant = WCWebcom(url: newParticipantPath)
                                                            wbcParticipant?.update(dicoAtt as NSObject,
                                                                                   onComplete: { errorUpdate in})
                                                        }
                                                    }
                                                    break
                                                }
                                            }
                                        }
        })
    }
    
    
    //Updates the user status when a reconnection occurs.
    @objc internal func updateUserStatus(notification: Notification) {
        
        guard let _ = webcomUserPath else {
            return
        }
        
        let wbcUsers = WCWebcom(url: webcomUserPath!)
        
        let wbcUserDisconnect = wbcUsers?.onDisconnect
        let dicoOnDisconnect = [Constant.User.Attribute.status: Constant.User.Status.disconnected]
        wbcUserDisconnect?.update(dicoOnDisconnect as NSObject)

        wbcUsers?.onceEventType(WCEventType.value,
                                withCallback: { (data, str) in
                                    
                                    let user = data?.exportVal() as? [String:Any?]
                                    
                                    guard let _ = user else {
                                        ///////////
                                        return
                                    }
                                    
                                    let dico = [Constant.User.Attribute.status: Constant.User.Status.connected] as [String: Any]
                                    
                                    wbcUsers?.update(dico as NSObject,
                                                     onComplete: { (errUpdt) in
                                                        
                                                        guard let _ = errUpdt else {
                                                            ///////////
                                                            return
                                                        }
                                                        ///////////
                                    })
        })
    }

    
    //Sends notifications when the websocket is on/off
    private func wsConnection() {
        
        let wbcCheckedConnection = WCWebcom.init(url: WATManager.setup.param!);
        wbcCheckedConnection!.child(Constant.webcomConnectionChildPath)?.onEventType(WCEventType.value,
                                                                                     withCallback: { (data, str) in
                                                                                        
                                                                                        guard let _ = (data?.value as? Bool) else {
                                                                                            return
                                                                                        }
                                                                                        
                                                                                        var notifName: String
                                                                                        
                                                                                        switch (data?.value as? Bool)! {
                                                                                            
                                                                                        case true:
                                                                                            DLog("☀️ WEBSOCKET ☀️ : \(Date())")
                                                                                            self.wsConnect.in = (true, Date().timeIntervalSince1970)
                                                                                            notifName = Constant.connectionOK
                                                                                            
                                                                                        case false:
                                                                                            DLog("☠️ WEBSOCKET ☠️ : \(Date())")
                                                                                            self.wsConnect.out = (true, Date().timeIntervalSince1970)
                                                                                            notifName = Constant.connectionNOK
                                                                                        }
                                                                                        
                                                                                        NotificationCenter.default.post(name: Notification.Name(notifName),
                                                                                                                        object: nil,
                                                                                                                        userInfo: nil)
                                                                                        
//                                                                                        let task = DispatchWorkItem {
//                                                                                                NotificationCenter.default.post(name: Notification.Name(Constant.connectionNOK),
//                                                                                                                                object: nil,
//                                                                                                                                userInfo: nil) }
//
//                                                                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constant.disconnectionTime,
//                                                                                                                          execute: task)
//                                                                                            task.cancel()
//                                                                                        }
        })
    }
}
