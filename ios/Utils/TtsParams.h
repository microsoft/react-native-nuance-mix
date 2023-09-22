//
//  TtsParams.h
//  XaasSample
//
//  Created by Chris LeBlanc on 2/6/23.
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <Foundation/Foundation.h>

@interface TtsParams : NSObject {
    id params;
}

+ (instancetype)sharedInstance;

-(void)loadParams;
-(id)getParams;

@end

