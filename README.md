# auv3test5
## ReadMe

This is an iOS audio test app that instantiates and runs a custom V3 AUAudioUnit subclass which implements a simple real-time tone generator for audio synthesis.  

The AUAudioUnit subclass is written in Objective C.  This allows the AUAudioUnit subclass code to use only the plain C subset of Objective C inside the audio thread context, which is done in order to meet Apple's (current) recommendations for real-time audio code.  

The rest of the test app is written in Swift (updated to Swift 5).  The Audio Unit is connected to AVAudioEngine in Swift.

In the test app UI, there is one button to generate a tone,
and one text field to display whether the microphone tap is live.

Created by http://www.nicholson.com/rhn/ - 
Distribution under the BSD 2-clause license.  No warrantees implied.


