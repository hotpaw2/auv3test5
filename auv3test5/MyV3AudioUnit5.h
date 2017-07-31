//
//  MyV3AudioUnit5.h
//  auv3test5
//
//  Created by Ronald Nicholson on 7/31/17.
//  Copyright © 2017 HotPaw Productions. 
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern long int toneCount;
extern double	sampleRateHz;
extern float	testFrequency;

extern long int testMagnitude;

extern void processBuffer(float *p, int len);

@interface MyV3AudioUnit5 : AUAudioUnit {
    AUAudioUnitBusArray	    *outputBusArray;
}
@end
