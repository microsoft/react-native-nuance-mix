//
//  AudioAdditions.h
//  AudioSession
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//
// Nuance Communications, Inc. provides this document without representation
// or warranty of any kind. The information in this document is subject to
// change without notice and does not represent a commitment by Nuance
// Communications, Inc. The software and/or databases described in this
// document are furnished under a license agreement and may be used or
// copied only in accordance with the terms of such license agreement.
// Without limiting the rights under copyright reserved herein, and except
// as permitted by such license agreement, no part of this document may be
// reproduced or transmitted in any form or by any means, including, without
// limitation, electronic, mechanical, photocopying, recording, or otherwise,
// or transferred to information storage and retrieval systems, without the
// prior written permission of Nuance Communications, Inc.
//
// Nuance, the Nuance logo, Nuance Recognizer, and Nuance Vocalizer are
// trademarks or registered trademarks of Nuance Communications, Inc. or its
// affiliates in the United States and/or other countries. All other
// trademarks referenced herein are the property of their respective owners.
//


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


extern const UInt32 kAudioUnitProperty_Enabled;
extern const UInt32 kAudioUnitProperty_Disabled;
extern const UInt32 kAudioUnitRemoteIO_InputBus;
extern const UInt32 kAudioUnitRemoteIO_OutputBus;


#define AADebugAudioRoute() AudioAdditionsDebugAudioRoute(__FILE__, __LINE__)

void AudioAdditionsDebugAudioRoute(const char *file, int line);


#define AACheckStatus(_status, _jump) do {                            \
    status = _status;                                                \
    if (status) {                                                   \
        NSLog(@"%s:%d Audio Error %d", __FILE__, __LINE__, (int)status); \
        goto _jump;                                                  \
    }                                                               \
} while (0)
