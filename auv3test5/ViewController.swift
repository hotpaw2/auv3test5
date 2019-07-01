//
//  ViewController.swift
//  auv3test5
//
//  Created by Ronald Nicholson on 7/31/17.
//  Copyright © 2017 HotPaw Productions.
//

import UIKit
import AudioToolbox
import AVFoundation


class ViewController: UIViewController {
    
    @IBOutlet var myButton1 : UIButton!             //
    @IBOutlet var myInfoLabel1 : UILabel!           // don't forget to wire up label to storyboard
    
    var displayTimer : CADisplayLink!
    var testCounter			    =  0
    
    var audioEngine : AVAudioEngine?    =  nil
    var myAUNode: AVAudioUnit?	    =  nil
    var mixer			    =  AVAudioMixerNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AudioStart()				    // put here to autostart for test purposes
    }
    
    // cause something to happening
    @IBAction func button1Tapped(_ sender : UIButton) {
        testCounter += 1
        myInfoLabel1.text = String(testCounter)
        toneCount = 44100 / 2;			    // play tone for 1/2 second
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // audio unit subroutines
    
    func audioSetup() {

        let sess = AVAudioSession.sharedInstance()
        try! sess.setCategory(AVAudioSession.Category.playAndRecord)

        do {
            try sess.setPreferredSampleRate(48000.0)
            sampleRateHz	= 48000.0
        } catch { sampleRateHz	= 44100.0 }	    // for Simulator and old devices
        do {
            let duration = 1.00 * (256.0/48000.0)
            try sess.setPreferredIOBufferDuration(duration)   // 256 samples
        } catch { }
        try! sess.setActive(true)
        
        audioEngine = AVAudioEngine()
        
        
        let myUnitType = kAudioUnitType_Generator
        let mySubType : OSType = 1
        
        let compDesc = AudioComponentDescription(componentType:     myUnitType,
                                                 componentSubType:  mySubType,
                                                 componentManufacturer: 0x666f6f20, // 4 hex byte OSType 'foo '
            componentFlags:        0,
            componentFlagsMask:    0 )
        
        AUAudioUnit.registerSubclass(MyV3AudioUnit5.self,
                                     as:        compDesc,
                                     name:      "MyV3AudioUnit5",   // my AUAudioUnit subclass
            version:   1 )
        
        let outFormat = audioEngine!.outputNode.outputFormat(forBus: 0)
        
        AVAudioUnit.instantiate(with: compDesc,
                                options: .init(rawValue: 0)) { (audiounit, error) in
                                    
                                    self.myAUNode = audiounit   // save AVAudioUnit
                                    
                                    self.audioEngine!.attach(audiounit!)
                                    
                                    self.audioEngine!.connect(audiounit!,
                                                              to: self.audioEngine!.mainMixerNode,
                                                              format: outFormat)
        }
    }
    
    func AudioStart() {
        
        let bus0 : AVAudioNodeBus   =  0    // output of the inputNode
        let inputNode   =  audioEngine!.inputNode
        let inputFormat =  inputNode.outputFormat(forBus: bus0)
        
        inputNode.installTap(onBus: bus0,
                              bufferSize: 512,
                              format: inputFormat ) {
                                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                                
                                let len = Int32(buffer.frameLength)
                                let ptr = buffer.floatChannelData![0]
                                processBuffer(ptr, len )            // call C function inside tap
        }
        
        let outputFormat = audioEngine!.outputNode.inputFormat(forBus: 0)  // AVAudioFormat
        sampleRateHz = Double(outputFormat.sampleRate)
        
        audioEngine!.connect(audioEngine!.mainMixerNode,
                             to: audioEngine!.outputNode,
                             format: outputFormat)
        
        audioEngine!.prepare()
        
        do {
            try audioEngine!.start()
            self.myInfoLabel1.text = "engine started"
        } catch let error as NSError {
            self.myInfoLabel1.text = (error.localizedDescription)
        }
        
        if (displayTimer == nil) {
            displayTimer = CADisplayLink(target: self,
                                         selector: #selector(self.updateView) )
            displayTimer.preferredFramesPerSecond = 60  // 60 Hz
            displayTimer.add(to: RunLoop.current,
                             forMode: RunLoop.Mode.common )
        }
    }
    
    // show that something is happening
    @objc func updateView() {
        myInfoLabel1.text = String(testCounter) + "" + String(testMagnitude)
    }
}
