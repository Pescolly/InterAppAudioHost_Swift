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

class ViewController: UIViewController, SelectIAAUViewControllerDelegate
{
	var connectedInstrument:Bool?
	var instrumentUnit:AudioUnit?
	var instrumentNode:AUNode?
	var effectNode:AUNode?
	var connectedEffect:Bool?
	var effectUnit:AudioUnit?
	var ioNode:AUNode?

	@IBOutlet var instrumentIconImageView:UIImageView?
	@IBOutlet var effectIconImageView:UIImageView?

	
	var graphStarted:Bool = false
	var audioGraph:AUGraph = nil
	var _instrumentSelectViewController:SelectIAAUViewController?
	var _effectSelectViewController:SelectIAAUViewController?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		createAUGraph()
		// Do any additional setup after loading the view, typically from a nib.
	}

	//protocols
	func selectIAAUViewController(viewController:SelectIAAUViewController, didSelectUnit audioUnit:InterAppAudioUnit)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func selectIAAUViewControllerWantsToClose(viewController: SelectIAAUViewController)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	//funcs
	func createAUGraph()
	{
		var ioUnit:AudioUnit = nil
		var newAudioGraph:AUGraph = nil
		
		let stat = NewAUGraph(&newAudioGraph)
	
		if stat == noErr
		{
			var ioUnitDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
			                                                  componentSubType: kAudioUnitSubType_RemoteIO,
			                                                  componentManufacturer: kAudioUnitManufacturer_Apple,
			                                                  componentFlags: 0,
			                                                  componentFlagsMask: 0)
			AUGraphAddNode(newAudioGraph, &ioUnitDescription, &ioNode!)
			
			AUGraphOpen(newAudioGraph)
			AUGraphNodeInfo(audioGraph,
			                ioNode!,
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
			
			AUGraphStart(audioGraph)
			graphStarted = true
		}
	}
	
	func stopAUGraph()
	{
		if graphStarted && audioGraph != nil
		{
			AUGraphStop(audioGraph)
			var outIsInit:DarwinBoolean = false
			AUGraphIsInitialized(audioGraph, &outIsInit)
			if outIsInit
			{
				AUGraphUninitialize(audioGraph)
			}
			
			graphStarted = false
		}
	}
	
	@IBAction func selectInstrument(sender : AnyObject)
	{
		let description : AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_RemoteInstrument,
		                                                                        componentSubType: 0,
		                                                                        componentManufacturer: 0,
		                                                                        componentFlags: 0,
		                                                                        componentFlagsMask: 0)
			
		_instrumentSelectViewController = SelectIAAUViewController(description: description)
		_instrumentSelectViewController?.delegate = self
		
		let navController:UINavigationController = UINavigationController(rootViewController: _instrumentSelectViewController!)
		self.presentViewController(navController, animated: true, completion: nil)
	}

	@IBAction func selectEffect(sender : AnyObject)
	{
		let description : AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_RemoteEffect,
		                                                                        componentSubType: 0,
		                                                                        componentManufacturer: 0,
		                                                                        componentFlags: 0,
		                                                                        componentFlagsMask: 0)
		
		_effectSelectViewController = SelectIAAUViewController(description: description)
		_effectSelectViewController?.delegate = self
		
		let navController:UINavigationController = UINavigationController(rootViewController: _effectSelectViewController!)
		self.presentViewController(navController, animated: true, completion: nil)
	}
	
	func connectInstrument(unit : InterAppAudioUnit)
	{
		self.stopAUGraph()
		
		var newInstrumentNode:AUNode?
		var desc = unit.compDescription
		AUGraphAddNode(self.audioGraph, &desc!, &newInstrumentNode!)
		
		if newInstrumentNode != nil
		{
			if self.instrumentNode != nil
			{
				AUGraphDisconnectNodeInput(self.audioGraph, self.instrumentNode!, 0)
				AUGraphRemoveNode(self.audioGraph, self.instrumentNode!)
				
				self.instrumentUnit = nil
			}
			
			self.instrumentNode = newInstrumentNode
			
			AUGraphNodeInfo(self.audioGraph, self.instrumentNode!, nil, &self.instrumentUnit!)
			
			if (self.effectNode != nil)
			{
				AUGraphConnectNodeInput(self.audioGraph, self.instrumentNode!, 0, self.effectNode!, 0)
			}
			else
			{
				AUGraphConnectNodeInput(self.audioGraph, self.instrumentNode!, 0, self.ioNode!, 0)
			}
			
			self.connectedInstrument = true
			self.instrumentIconImageView!.image = unit.icon
		}
		else
		{
			self.startStopGraphAsRequired()
			CAShow(&self.audioGraph)
		}
		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

