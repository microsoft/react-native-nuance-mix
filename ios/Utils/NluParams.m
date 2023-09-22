//
//  NluParams.m
//  XaasSample
//
//  Created by Chris LeBlanc on 2/6/23.
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <Foundation/Foundation.h>
#import "NluParams.h"

@implementation NluParams

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)loadParams {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"params.nlu" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    params = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

- (id)getParams {
    return params;
}
@end

