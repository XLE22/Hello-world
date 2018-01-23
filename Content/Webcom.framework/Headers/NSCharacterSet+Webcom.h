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
//  NSCharacterSet+Webcom.h
//  Webcom
//
//  Created by Florent Maitre.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A `NSCharacterSet` category for the Webcom framework.
 */
@interface NSCharacterSet (Webcom)

/**
 @name Class Methods
 */

/**
 Returns a set containing the characters which are allowed in a Webcom path.

 @return The character set for a Webcom path.
 */
+ (NSCharacterSet *)webcomURLPathAllowedCharacterSet;

@end

NS_ASSUME_NONNULL_END
