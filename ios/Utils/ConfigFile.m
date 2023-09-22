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
#import "ConfigFile.h"

@implementation ConfigFile

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)loadConfig {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSDictionary *xaas_urls = [dict objectForKey:@"xaas_urls"];

    clientId = [dict objectForKey:@"client_id"];
    clientSecret = [dict objectForKey:@"client_secret"];
    tokenUrl = [dict objectForKey:@"token_url"];
    asrUrl = [xaas_urls objectForKey:@"asr"];
    ttsUrl = [xaas_urls objectForKey:@"tts"];
    nluUrl = [xaas_urls objectForKey:@"nlu"];
    dlgUrl = [xaas_urls objectForKey:@"dlg"];
}
-(NSString *)getTokenUrl {
    return tokenUrl;
}

-(NSString *)getUrl:(NSString *)scope {
    if ([scope isEqualToString:@"nlu"]) {
        return nluUrl;
    }
    else if ([scope isEqualToString:@"asr"]) {
        return asrUrl;
    }
    else if ([scope isEqualToString:@"tts"]) {
        return ttsUrl;
    }
    else if ([scope isEqualToString:@"dlg"]) {
        return dlgUrl;
    }
    return @"bad scope";
}

-(NSString *)getClientId {
    return clientId;
}

-(NSString *)getClientSecret {
    return clientSecret;
}

@end

