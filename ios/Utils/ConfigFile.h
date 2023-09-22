//
//  Config.m
//  XaasSample
//
//  Created by Chris LeBlanc on 1/16/20.
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <Foundation/Foundation.h>

@interface ConfigFile : NSObject {
    NSString *asrUrl;
    NSString *ttsUrl;
    NSString *nluUrl;
    NSString *dlgUrl;
    NSString *clientId;
    NSString *clientSecret;
    NSString *tokenUrl;
}

+ (instancetype)sharedInstance;

-(void)loadConfig;
-(NSString *)getTokenUrl;
-(NSString *)getUrl:(NSString *)scope;
-(NSString *)getClientId;
-(NSString *)getClientSecret;

@end

