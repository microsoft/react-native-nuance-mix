//
//  Authenticator.h
//  XaasSample
//
//  Created by Chris LeBlanc on 1/16/20.
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Authenticator : NSObject<NSURLConnectionDelegate> {
    NSMutableData *_responseData;
    NSString *_accessToken;
    NSString *_tokenType;
}

+ (instancetype)sharedInstance;

- (NSString *)getTokenType;
- (NSString *)Authenticate:(NSString *)scope;

@end
