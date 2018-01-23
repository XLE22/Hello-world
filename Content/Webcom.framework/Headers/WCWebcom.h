/*
 * Webcom iOS Client SDK
 * Build realtime apps. Share and sync data instantly between your clients
 *
 * Copyright (C) <2015> Orange
 *
 * This software is confidential and proprietary information of Orange.
 * You shall not disclose such Confidential Information and shall use it only in
 * accordance with the terms of the agreement you entered into.
 * Unauthorized copying of this file, via any medium is strictly prohibited.
 *
 * If you are Orange employee you shall use this software in accordance with
 * the Orange Source Charter (http://opensource.itn.ftgroup/index.php/Orange_Source_Charter)
 */

//
//  WCWebcom.h
//  Webcom
//
//  Created by Christophe Azemar.
//
//

#import <Foundation/Foundation.h>
#import "WCAuthInfo.h"
#import "WCDataSnapshot.h"
#import "WCOAuth2UserInfoFromProvider.h"
#import "WCOnDisconnect.h"
#import "WCQuery.h"
#import "WCWebcomError.h"



NS_ASSUME_NONNULL_BEGIN
/**
 A `WCWebcom` instance represents a particular location in your namespace and can be used for reading or writing data to that location.
 
 Reading data can be done with `on(_:)` and `once(_:)` methods and writing data can be done with `set(_:)`, `push(_:)`, `update(_:)` and `remove(_:)` methods
 
 A `WCWebcom` instance is useful to read and write data at a defined location, specified by a URL parameter. You can also use specific methods and properties (for instance `child(_:)`, `parent`, or `root`) to navigate into data structure.
 */
@interface WCWebcom : WCQuery

/**
 @name Initializing a Webcom instance
 */

/**
 Instantiates a Webcom location with the specified URL

 @param uri The server URL
 @return The Webcom instance
 */
- (nullable id)initWithURL:(NSString *)uri;

/** 
 @name Accessing Parent and Child Locations
 */

/**
 Retrieves a Webcom instance at a given path.
 
 @param path The relative path from the current location.
 @return The Webcom instance which targets the specified path.
 */
- (nullable WCWebcom *)child:(NSString *)path;

/**
 The key name of Webcom instance.
 */
@property(nonatomic, readonly, nullable) NSString * name;

/**
 The Webcom parent for this location.
 */
@property(nonatomic, readonly, nullable) WCWebcom * parent;

/**
 The Webcom reference for the location.
 */
@property(nonatomic, readonly, nullable) WCWebcom * ref;

/**
 The Webcom root of the current namespace.
 */
@property(nonatomic, readonly, nullable) WCWebcom * root;

/**
 @name Authenticating
 */

/**
 Authenticates the user with a token or a Webcom secret.

 @param token The token or Webcom secret. Only use secret for server authentication. Be careful, it gives full control over namespace.
 @param completeCallback A block called once authentication is complete. On failure, the first argument contains the details of the error. The second argument contains information about the authentication.
 */
- (void)authWithToken:(NSString *)token
           onComplete:(void (^) (NSError * _Nullable error,
                                 WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 Authenticates the user with a token or a Webcom secret.

 @param token The token or Webcom secret. Only use secret for server authentication. Be careful, it gives full control over namespace.
 @param completeCallback A block called once authentication is complete. On failure, the first argument contains error details. The second argument contains information about the authentication.
 @param cancelCallback A block called when authentication is cancelled because of expired token. The first argument contains error details.
 */
- (void)authWithToken:(NSString *)token
           onComplete:(void (^) (NSError * _Nullable error,
                                 WCAuthInfo * _Nullable authInfo))completeCallback
             onCancel:(nullable void (^) (NSError * _Nullable error))cancelCallback;

/**
 Authenticates the user using an email and a password.

 @param mail The user's email.
 @param password The user's password.
 @param rememberMe Indicates if the session should last.
 @param completeCallback A block called once authentication is complete. On failure, the first argument contains error details. The second argument contains information about the authentication.
 */
- (void)authWithMail:(NSString *)mail
         andPassword:(NSString *)password
       andRememberMe:(BOOL)rememberMe
          onComplete:(void (^) (NSError * _Nullable error,
                                WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 Logouts the currently authenticated user
 */
- (void)logout;

/**
 Logouts the currently authenticated user

 @param completeCallback A block called when the server finished logout. An error can be passed as the parameter if something went wrong.
 */
- (void)logoutWithCallback:(nullable void (^) (NSError * _Nullable error))completeCallback;

/**
 Authenticates the user thanks to the OAuth 2.0 protocol.
 
 @param provider The provider's name (orange, google...). Let's see the tutorial about oAuth2 to have the complete list and the accurate writing.
 @param completeCallback A block called once authentication is complete. On failure, the first argument contains error details. The second argument contains desired information about the access token returned by the provider.
 @param cancelCallback A block called once the user clicked on the 'cancel' button.
*/
- (void)oAuth2Provider:(NSString *)provider
            onComplete:(void (^)(NSError * _Nullable error,
                                 WCOAuth2UserInfoFromProvider * _Nullable authInfo))completeCallback
              onCancel:(void (^)(NSError *))cancelCallback;
/**
 Resumes authentication

 @param callback A block called when the session is resumed.
 */
- (void)resumeWithCallback:(void (^) (NSError * _Nullable error,
                                      WCAuthInfo * _Nullable authInfo))callback;

/**
 Unauthenticates the user
 */
- (void)unauth;

/**
 @name Managing Users
 */

/**
 Changes the password of an existing user using specified email and password.
 
 @param userMail The user's email.
 @param oldPassword The user's old password.
 @param newPassword The user's new password.
 @param completeCallback A block called when the user account has been changed. On failure, the first argument contains error details.
 */
- (void)changePasswordForUser:(NSString *)userMail
              fromOldPassword:(NSString *)oldPassword
                toNewPassword:(NSString *)newPassword
                   onComplete:(void (^) (NSError * _Nullable error,
                                         WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 Creates a new user account using specified email and password.

 @param options Dictionary containing "email" and "password" as keys.
 @param completeCallback A block called when the user account has been created. On failure, the first argument contains error details.
 */
- (void)createUser:(NSDictionary *)options
        onComplete:(void (^) (NSError * _Nullable error,
                              WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 Removes an existing user account using specified email and password.

 @param userMail The user's email.
 @param password The user's password.
 @param completeCallback A block called when the user account has been deleted. On failure, the first argument contains error details.
 */
- (void)removeUser:(NSString *)userMail
      withPassword:(NSString *)password
        onComplete:(void (^) (NSError * _Nullable error,
                              WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 Sends a password-reset email to the owner of the account. The email contains a token that may be used to authenticate and change the user's password.

 @param userMail The user's email.
 @param completeCallback A block called when the email has been sent. On failure, the first argument contains error details.
 */
- (void)sendPasswordResetForUser:(NSString *)userMail
                      onComplete:(void (^) (NSError * _Nullable error,
                                            WCAuthInfo * _Nullable authInfo))completeCallback;

/**
 @name Managing Connection
 */

/**
 Forces reconnection and enables the retry connection feature.
 */
- (void)goOnline;

/**
 Forces disconnection and disables the retry connection feature.
 */
- (void)goOffline;

/**
 The `WCOnDisconnect` object attached to this Webcom location.
 */
@property(nonatomic, readonly, nullable) WCOnDisconnect * onDisconnect;

/**
 @name Writing Data
 */

/**
 
 */
/**
 Adds a new empty child at current location. Its key is automatically generated and is always unique.

 @return The Webcom object for added location.
 */
- (WCWebcom * _Nullable)push;

/**
 Adds a new child at current location. Its key is automatically generated and is always unique.

 @param value The value of the new child.
 @return The Webcom object for added location.
 */
- (WCWebcom * _Nullable)push:(nullable NSObject *)value;

/**
 Adds a new child at current location. Its key is automatically generated and is always unique.

 @param value The value of the new child.
 @param completeCallback A block called after synchronization with the server. An error can be passed as the first argument.
 @return The Webcom object for added location.
 */
- (WCWebcom * _Nullable)push:(nullable NSObject *)value
                  onComplete:(nullable void (^) (NSError * _Nullable error))completeCallback;

/**
 Removes data at current location.
 */
- (void)remove;

/**
 Removes data at current location.
 
 @param completeCallback A block called after synchronization with the server. An error can be passed as the first argument.
 */
- (void)removeOnComplete:(nullable void (^) (NSError * _Nullable error))completeCallback;

/**
 Writes empty data at current location.
 */
- (void)set;

/**
 Writes data at current location.

 @param value The new object value.
 */
- (void)set:(nullable NSObject *)value;

/**
 Writes data at current location.

 @param value The new object value.
 @param completeCallback A block called after synchronization with the server. An error can be passed as the first argument.
 */
- (void)set:(nullable NSObject *)value
 onComplete:(nullable void (^) (NSError * _Nullable error))completeCallback;

/**
 Updates data at current location.

 @param value The child to be updated or added
 */
- (void)update:(NSObject *)value;

/**
 Updates data at current location.

 @param value The child to be updated or added
 @param completeCallback A block called after synchronization with the server. An error can be passed as the first argument.
 */
- (void)update:(NSObject *)value
    onComplete:(nullable void (^) (NSError * _Nullable error))completeCallback;

/**
 @name Working with URLs
 */

/**
 Returns the absolute URL of the Webcom instance

 @return The absolute URL
 */
- (nullable NSString *)toString;

@end

NS_ASSUME_NONNULL_END
