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
	var connectedInstrument:Bool = false
	var instrumentUnit:AudioUnit = nil
	var instrumentNode:AUNode = AUNode()
	var effectNode:AUNode?
	var connectedEffect:Bool?
	var effectUnit:AudioUnit?
	var ioNode = AUNode()
	var ioUnit:AudioUnit = nil
	
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
		if (viewController == _instrumentSelectViewController)
		{
			self.connectInstrument(audioUnit)
		}
		else if (viewController == _effectSelectViewController)
		{
			self.connectEffect(audioUnit)
		}
	}
	
	func selectIAAUViewControllerWantsToClose(viewController: SelectIAAUViewController)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	//funcs
	func createAUGraph()
	{
		let stat = NewAUGraph(&self.audioGraph)
		
		if stat == noErr
		{
			var ioUnitDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
			                                                  componentSubType: kAudioUnitSubType_RemoteIO,
			                                                  componentManufacturer: kAudioUnitManufacturer_Apple,
			                                                  componentFlags: 0,
			                                                  componentFlagsMask: 0)
			AUGraphAddNode(self.audioGraph, &ioUnitDescription, &self.ioNode)
			
			AUGraphOpen(self.audioGraph)
			
			AUGraphNodeInfo(self.audioGraph, self.ioNode, nil, &self.ioUnit)
			
			let session = AVAudioSession.sharedInstance()
			var format = AudioStreamBasicDescription()
			format.mSampleRate = session.sampleRate
			format.mFormatID = kAudioFormatLinearPCM
			format.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved
			format.mBytesPerPacket = 4
			format.mFramesPerPacket = 1
			format.mBytesPerFrame = 4
			format.mChannelsPerFrame = 2
			format.mBitsPerChannel = 32
			
			AudioUnitSetProperty(self.ioUnit,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Output,
			                     1,
			                     &format,
			                     UInt32(sizeof(AudioStreamBasicDescription)))
			
			AudioUnitSetProperty(self.ioUnit,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Input,
			                     0,
			                     &format,
			                     UInt32(sizeof(AudioStreamBasicDescription)))
			
			CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph))
			
			
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
		if (connectedInstrument)
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
		
		self._instrumentSelectViewController = SelectIAAUViewController(withSearchDescription: description)
		self._instrumentSelectViewController?.delegate = self
		
		let navController:UINavigationController = UINavigationController(rootViewController: self._instrumentSelectViewController!)
		self.presentViewController(navController, animated: true, completion: nil)
	}
	
	@IBAction func selectEffect(sender : AnyObject)
	{
		let description : AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_RemoteEffect,
		                                                                        componentSubType: 0,
		                                                                        componentManufacturer: 0,
		                                                                        componentFlags: 0,
		                                                                        componentFlagsMask: 0)
		
		_effectSelectViewController = SelectIAAUViewController(withSearchDescription: description)
		_effectSelectViewController?.delegate = self
		
		let navController:UINavigationController = UINavigationController(rootViewController: _effectSelectViewController!)
		self.presentViewController(navController, animated: true, completion: nil)
	}
	
	func connectEffect(audioUnit : InterAppAudioUnit)
	{
		if !connectedInstrument
		{
			let alert = UIAlertView(title: "ERROR",
			                        message: "You need to select instrument first",
			                        delegate: nil,
			                        cancelButtonTitle: nil,
			                        otherButtonTitles: "OK",
			                        "")
			alert.show()
		}
	}
	
	func connectInstrument(unit : InterAppAudioUnit)
	{
		print ("instrument selected")
		
		self.stopAUGraph()
		
		var newInstrumentNode:AUNode = AUNode()
		var desc:AudioComponentDescription = unit.compDescription!
		AUGraphAddNode(self.audioGraph, &desc, &newInstrumentNode)
		
		if self.instrumentNode != 0
		{
			AUGraphDisconnectNodeInput(self.audioGraph, self.instrumentNode, 0)
			AUGraphRemoveNode(self.audioGraph, self.instrumentNode)
			self.instrumentIconImageView?.image = nil
			self.instrumentUnit = nil
		}
		
		self.instrumentNode = newInstrumentNode
		
		AUGraphNodeInfo(self.audioGraph, self.instrumentNode, nil, &self.instrumentUnit)
		
		if (self.effectNode != nil)
		{
			AUGraphConnectNodeInput(self.audioGraph, self.instrumentNode, 0, self.effectNode!, 0)
		}
		else
		{
			AUGraphConnectNodeInput(self.audioGraph, self.instrumentNode, 0, self.ioNode, 0)
		}
	
		self.connectedInstrument = true
		self.instrumentIconImageView!.image = unit.icon
		
		self.startStopGraphAsRequired()
		CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph))
		
	}
	
	@IBAction func playNote(sender : AnyObject)
	{
		if self.connectedInstrument
		{
			let noteOnCommand:UInt32 = (0x9 << 4) | 0
			MusicDeviceMIDIEvent(self.instrumentUnit, noteOnCommand, 60, 100, 0)
			
			let delayInSeconds:UInt64 = 2
			let popTime:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64((delayInSeconds * NSEC_PER_SEC)))
			
			dispatch_after(popTime, dispatch_get_main_queue(), {
				() in
				if self.connectedInstrument
				{
					let noteOffCommand:UInt32 = (0x8 << 4) | 0
					MusicDeviceMIDIEvent(self.instrumentUnit, noteOffCommand, 60, 100, 0)
				}
			})
		}
	}
	
	@IBAction func record(sender : UIButton)
	{
		let fileURL = createTempURL("TEMPFILE")	// Create temporary file

		let renderCallback :  @convention(c) (UnsafeMutablePointer<()>, UnsafeMutablePointer<AudioUnitRenderActionFlags>,
			UnsafePointer<AudioTimeStamp>, UInt32, UInt32, UnsafeMutablePointer<AudioBufferList>) -> Int32 = {
			(indata, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> Int32 in
				//do actual render here
				let extAudioFile = ExtAudioFileRef()
				ExtAudioFileOpenURL(fileURL, extAudioFile)
				ExtAudioFileWriteAsync(extAudioFile, inNumberFrames, ioData)
				return noErr
		}

		
		var inputCallback = AURenderCallbackStruct(inputProc: renderCallback, inputProcRefCon: nil)
		
		AudioUnitSetProperty(self.ioUnit,
		                     kAudioOutputUnitProperty_SetInputCallback,
		                     kAudioUnitScope_Global,
		                     0,
		                     &inputCallback,
		                     UInt32(sizeof(AURenderCallbackStruct)))
	}

	
	/*
		if self.connectedInstrument
		{
			recorder->Stop();
			recorder->Close();
			delete recorder;
			
			recorder = new CAAudioUnitOutputCapturer(instrument, (CFURLRef)fileURL, kAudioFileCAFType, tapFormat, 0);
			
			recorder->Start();
			state = TransportStateRecording;
			mTranslatedLastTimeRendered = 0;
			canPlay = NO;
		}
	
	*/
		
	@IBAction func stopRecording(sender : UIButton)
	{
		/*
		- (void) stopRecording {
			if (state == TransportStateRecording) {
				if (recorder) {
					recorder->Stop();
					recorder->Close();
				}
				
				canPlay = YES;
				mTranslatedLastTimeRendered = 0;
				
				if (fileURL && [[NSFileManager defaultManager] isReadableFileAtPath: fileURL.path] && canPlay) {         //Calculate duration
					Check(AudioFileOpenURL((CFURLRef)fileURL, kAudioFileReadPermission, 0, &filePlayer.inputFile));
					UInt32 propSize = sizeof(filePlayer.inputFormat);
					Check(AudioFileGetProperty(filePlayer.inputFile, kAudioFilePropertyDataFormat, &propSize, &filePlayer.inputFormat));
					UInt64 nPackets;
					propSize = sizeof(nPackets);
					Check(AudioFileGetProperty(filePlayer.inputFile,
						kAudioFilePropertyAudioDataPacketCount,
						&propSize, &nPackets));
					durationOfFile = nPackets * filePlayer.inputFormat.mFramesPerPacket;
				}
				state = TransportStateStopped;
				[self notifyObservers];
				canRewind = YES;
			}
		}
		*/
	}
	
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}

