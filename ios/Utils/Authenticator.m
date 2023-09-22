//
//  Authenticator.m
//  XaasSample
//
//  Created by Chris LeBlanc on 1/16/20.
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Authenticator.h"
#import "ConfigFile.h"

#define TOKEN_MAX_AGE 780 // 13 minutes in seconds

@implementation Authenticator

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)loadCredentials:(NSString *) scope {
    ConfigFile * c = [ConfigFile alloc];
    [c loadConfig];
}

-(BOOL)tokenValid:(NSString *) scope {
    // Check if the token cache exists
    NSString *homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *tokenFileName = [NSString stringWithFormat:@"token.%@.cache", scope];
    NSString *filepath = [homeDir stringByAppendingPathComponent:tokenFileName];
    NSError *error;
    _accessToken = [[NSString alloc] initWithContentsOfFile:filepath encoding:NSUnicodeStringEncoding error:&error];
    if (_accessToken == NULL) {
        NSLog(@"Error: %@", error);
        return NO;
    }
    // Check to see if it's expired
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: filepath error:&error];
    if (attributes != nil) {
        NSDate *lastDate = (NSDate*)[attributes objectForKey: NSFileModificationDate];
        if ([[NSDate date] timeIntervalSince1970] - [lastDate timeIntervalSince1970] > TOKEN_MAX_AGE) {
            return NO;
        }
    }
    else {
        return NO;
    }
    return YES;
}

-(BOOL)generateToken:(NSString *) scope {
    ConfigFile *c = [ConfigFile alloc];
    [c loadConfig];
    NSString *clientId = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes
                                        (kCFAllocatorDefault,
                                         (__bridge CFStringRef)[c getClientId],
                                         NULL,
                                         CFSTR("!*'();:@&=+$,/?%#[]"),
                                         kCFStringEncodingUTF8)
                                        );
    NSString *cid = [clientId stringByAppendingString:@":"];
    NSString *auth = [cid stringByAppendingString:[c getClientSecret]];
    NSData *nsdata = [auth dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authentication = [nsdata base64EncodedStringWithOptions:0];
    NSString *content = [NSString stringWithFormat:@"grant_type=client_credentials&scope=%@", scope];
    NSURL *tokenUrl = [NSURL URLWithString:[c getTokenUrl]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenUrl];
    // Specify that it will be a POST request
    request.HTTPMethod = @"POST";
    // This is how we set header fields
    [request setValue:[@"Basic " stringByAppendingString:authentication] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSData *requestBodyData = [content dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBodyData;

    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        
    if (error != nil)
    {
        NSLog(@"Error getting access token");
        _accessToken = @"Error getting access token";
        return NO;
    }
    NSDictionary *token = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    _accessToken = [token objectForKey:@"access_token"];
    _tokenType = [token objectForKey:@"token_type"];
    return YES;
}

-(BOOL)cacheToken:(NSString *) scope {
    NSString *homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *tokenFileName = [NSString stringWithFormat:@"token.%@.cache", scope];
    NSString *filepath = [homeDir stringByAppendingPathComponent:tokenFileName];
    NSError *error;

    BOOL ok = [_accessToken writeToFile:filepath atomically:YES encoding:NSUnicodeStringEncoding error:&error];
    return ok;
}

-(NSString *)getTokenType {
    return _tokenType;
}

-(NSString *)Authenticate:(NSString *) scope {
    if ([self tokenValid: scope]) {
        return _accessToken;
    }
    if ([self generateToken: scope]) {
        if ([self cacheToken: scope]) {
            return _accessToken;
        }
        return @"Error caching token";
    }
    return @"Error generating token";
}
@end

