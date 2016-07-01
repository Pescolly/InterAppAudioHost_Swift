//
//  ViewController.swift
//  AudioHost
//
//  Created by armen karamian on 6/29/16.
//  Copyright © 2016 armen karamian. All rights reserved.
//

import UIKit
import AudioUnit
import AVFoundation

class ViewController: UIViewController
{
	var connectedInstrument:Bool?
	var graphStarted:Bool = false
	var audioGraph:AUGraph = nil

	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		createAUGraph()
		// Do any additional setup after loading the view, typically from a nib.
	}

	func createAUGraph()
	{
		var ioUnit:AudioUnit = nil
		var instrumentUnit:AudioUnit
		var effectUnit:AudioUnit
		var ioNode:AUNode = 0
		var instrumentNode:AUNode = 0
		var effectNode:AUNode = 0
		var connectedEffect:Bool
		var newAudioGraph:AUGraph = nil
		
		let stat = NewAUGraph(&newAudioGraph)
	
		if stat == noErr
		{
			var ioUnitDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
			                                                  componentSubType: kAudioUnitSubType_RemoteIO,
			                                                  componentManufacturer: kAudioUnitManufacturer_Apple,
			                                                  componentFlags: 0,
			                                                  componentFlagsMask: 0)
			AUGraphAddNode(newAudioGraph, &ioUnitDescription, &ioNode)
			
			AUGraphOpen(newAudioGraph)
			AUGraphNodeInfo(audioGraph,
			                ioNode,
			                nil,
			                &ioUnit)
			
			var session = AVAudioSession.sharedInstance()
			var format = AudioStreamBasicDescription()
			format.mSampleRate = session.sampleRate
			format.mFormatID = kAudioFormatLinearPCM
			format.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved
			format.mBytesPerPacket = 4
			format.mFramesPerPacket = 1
			format.mBytesPerFrame = 4
			format.mChannelsPerFrame = 2
			format.mBitsPerChannel = 32
			
			AudioUnitSetProperty(ioUnit,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Output,
			                     1,
			                     &format,
			                     UInt32(sizeof(AudioStreamBasicDescription)))
			
			AudioUnitSetProperty(ioUnit,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Input,
			                     0,
			                     &format,
			                     UInt32(sizeof(AudioStreamBasicDescription)))
			
			CAShow(UnsafeMutablePointer<AUGraph>(newAudioGraph))
			
		}
		else
		{
			print ("Err: ", stat)
		}
	}
	
	func startAudioSession()
	{
		do
		{
			let session = AVAudioSession.sharedInstance()
			try session.setPreferredSampleRate(session.sampleRate)
			try session.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
			try session.setActive(true)
			
		}
		catch
		{
			print("FAILS")
		}
	}
	
	func startStopGraphAsRequired()
	{
		if (connectedInstrument != nil)
		{
			self.startAUGraph()
		}
		else
		{
			self.stopAUGraph()
		}
	}
	
	func startAUGraph()
	{
		if (!graphStarted)
		{
			self.startAudioSession()
			
			var outIsInit:DarwinBoolean = false
			AUGraphIsInitialized(audioGraph, &outIsInit)
			if (!outIsInit)
			{
				AUGraphInitialize(audioGraph)
			}
		}
	}
	
	func stopAUGraph()
	{
		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

