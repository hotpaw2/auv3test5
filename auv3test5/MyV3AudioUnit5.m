//
//  MyV3AudioUnit5.m
//  auv3test5
//
//  Created by Ronald Nicholson on 7/31/17.
//  Copyright © 2017 HotPaw Productions.
//

//  Audio Unit subclass created in Objective C ,
//    but using only the C subset inside the audio callback context
//    to meet real-time audio predictable latency requirements:
//       - no Obj C or Swift runtime (as per WWDC 2017 session on Core Audio)
//       - no memory management
//       - no potentially blocking locks or GCD calls

#import "MyV3AudioUnit5.h"

long int    toneCount;
float	    testFrequency   =    880.0;		// an audio frequency in Hz
float	    testVolume	    =      0.5;		// volume setting
double	    sampleRateHz    =  48000.0;

@interface MyV3AudioUnit5 ()
@property AUAudioUnitBusArray *outputBusArray;
@end

@implementation MyV3AudioUnit5 {	    // an eXperimental V3 AudioUnit
                                            // float		    frequency;
    AudioBufferList const   *myAudioBufferList;
    AVAudioPCMBuffer	    *my_pcmBuffer;
    AUAudioUnitBus	    *outputBus;
}

// @synthesize parameterTree;
@synthesize outputBusArray;


- (instancetype)initWithComponentDescription: (AudioComponentDescription)componentDescription
                                     options: (AudioComponentInstantiationOptions)options
                                       error: (NSError **)outError {
    
    self = [super initWithComponentDescription: componentDescription
                                       options: options
                                         error: outError];
    
    if (self == nil) { return nil; }
    
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc]
                                    initStandardFormatWithSampleRate: sampleRateHz
                                    channels: 2];
    
    outputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];
    outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit: self
                                                            busType: AUAudioUnitBusTypeOutput
                                                             busses: @[outputBus]];
    
    self.maximumFramesToRender =  512;
    
    return self;
}

- (AUAudioUnitBusArray *)outputBusses {
    return outputBusArray;
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) { return NO; }
    
    my_pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputBus.format
                                                 frameCapacity: 4096];
    myAudioBufferList = my_pcmBuffer.audioBufferList;
    return YES;
}

- (void)deallocateRenderResources {
    [super deallocateRenderResources];
}

// sometimes the buffers come back nil, so fix them
void repairOutputBufferList(AudioBufferList	*outBufferList,
                            AVAudioFrameCount	frameCount,
                            bool			zeroFill,
                            AudioBufferList const  *myAudioBufferList) {
    
    UInt32  byteSize		    =  frameCount * sizeof(float);
    int	    numberOfOutputBuffers   =  outBufferList->mNumberBuffers;
    if (numberOfOutputBuffers > 2) { numberOfOutputBuffers = 2; }
    
    for (int i = 0; i < numberOfOutputBuffers; ++i) {
        outBufferList->mBuffers[i].mNumberChannels = myAudioBufferList->mBuffers[i].mNumberChannels;
        outBufferList->mBuffers[i].mDataByteSize = byteSize;	// set buffer size
        if (outBufferList->mBuffers[i].mData == NULL) {		// copy buffer pointers if needed
            outBufferList->mBuffers[i].mData = myAudioBufferList->mBuffers[i].mData;
        }
        if (zeroFill) { memset(outBufferList->mBuffers[i].mData, 0, byteSize); }
    }
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

static float ph = 0.0;		// save phase

- (AUInternalRenderBlock)internalRenderBlock {
    
    AudioBufferList const   **myABLCaptured	=  &myAudioBufferList;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags    *actionFlags,
                              const AudioTimeStamp	    *timestamp,
                              AVAudioFrameCount		    frameCount,
                              NSInteger			    outputBusNumber,
                              AudioBufferList		    *outputBufferListPtr,
                              const AURenderEvent	    *realtimeEventListHead,
                              AURenderPullInputBlock	    pullInputBlock ) {
        
        int numBuffers = outputBufferListPtr->mNumberBuffers;
        
        AudioBufferList const	*tmpABL	=   *myABLCaptured;
        repairOutputBufferList(outputBufferListPtr, frameCount, false, tmpABL);
        
        float *ptrLeft  = (float*)outputBufferListPtr->mBuffers[0].mData;
        float *ptrRight = NULL;
        if (numBuffers == 2) {
            ptrRight    = (float*)outputBufferListPtr->mBuffers[1].mData;
        }
        
        // example C routine to create an audio output waveform
        if (1) {
            int   n  = frameCount;
            float f0 = testFrequency;
            float v0 = testVolume;
            float dp = 2.0 * M_PI * f0 / sampleRateHz;	// calculate phase increment
            
            for (int i=0;i<n;i++) {
                float x = 0.0;		// default to silence
                if (toneCount > 0) {	// or create a sinewave
                    x = v0 * sinf(ph); ph = ph + dp;
                    // sin function is more accurate if angle is within the normal range
                    if (ph > M_PI) { ph -= 2.0 * M_PI; }
                    toneCount -= 1;	// decrement tone length counter
                }
                if (ptrLeft  != NULL) { ptrLeft[ i] = x; }  // write samples to buffer
                if (ptrRight != NULL) { ptrRight[i] = x; }
            }
        }
        
        return noErr;
    };
}

@end

#pragma mark -- example C routine to process input samples ---

long int    testMagnitude   =      0;

void processBuffer(float *p, int len)
{
    // example C routine to analyze audio input samples
    float y = 0.0;
    if (p != NULL && len > 2) {
        for (int i=0; i<len; i++) {
            float x = 32768.0f * p[i];
            y += (x * x);
        }
        if (y > 0.0) {
            testMagnitude = 10.0f * log10f(y / len);
        }
    }
}

// eof
