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
import AudioToolbox


let fileURL = createTempURL("TEMPFILE.caf")	// Create temporary file

let renderCallback :  @convention(c) (UnsafeMutablePointer<()>, UnsafeMutablePointer<AudioUnitRenderActionFlags>,
	UnsafePointer<AudioTimeStamp>, UInt32, UInt32, UnsafeMutablePointer<AudioBufferList>) -> Int32 = {
		(indata, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> Int32 in
		//do actual render here
		NSLog("in callback", fileURL)
		var extAudioFile = ExtAudioFileRef()
		let openfilestat = ExtAudioFileOpenURL(fileURL, &extAudioFile)
		NSLog("open file stat: %d",openfilestat)
		let extaudiowrite = ExtAudioFileWriteAsync(extAudioFile, inNumberFrames, ioData)
		NSLog("ext audio write stat: %d", extaudiowrite)
		return noErr
}

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
	var format = AudioStreamBasicDescription()
	
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
		
		NSLog("writing to file", fileURL)
		
		//setup format
		let session = AVAudioSession.sharedInstance()
		
		self.format.mSampleRate = session.sampleRate
		self.format.mFormatID = kAudioFormatLinearPCM
		self.format.mFormatFlags = kAudioFormatFlagIsFloat
		self.format.mBytesPerPacket = 4
		self.format.mFramesPerPacket = 1
		self.format.mBytesPerFrame = 4
		self.format.mChannelsPerFrame = 1
		self.format.mBitsPerChannel = 32
		
		//do test file
		
		var extAudioFile:ExtAudioFileRef = nil
		let filecreatestat = ExtAudioFileCreateWithURL(fileURL, kAudioFileCAFType, &self.format, nil, 1, &extAudioFile)
		let fileopenstat = ExtAudioFileOpenURL(fileURL, &extAudioFile)

		if filecreatestat == noErr && fileopenstat == noErr
		{
			NSLog("file created")
		}
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
			NSLog("Err: ", stat)
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
			NSLog("Audio session active")
			
		}
		catch
		{
			NSLog("FAILS")
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
			NSLog("Graph is initialized and started")
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
		NSLog("instrument selected")
		
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
		
		
		//record ioUnit input using callback
		if self.ioUnit != nil
		{
			CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph))

			
			
			var inputCallback = AURenderCallbackStruct(inputProc: renderCallback, inputProcRefCon: nil)
			let ausetProperty = AudioUnitSetProperty(self.ioUnit,
			                     kAudioOutputUnitProperty_SetInputCallback,
			                     kAudioUnitScope_Global,
			                     0,
			                     &inputCallback,
			                     UInt32(sizeof(AURenderCallbackStruct)))
			NSLog("AUSetProperty stat: %d", ausetProperty)
			let rendernotifyStat = AudioUnitAddRenderNotify(self.ioUnit, renderCallback, nil)
			NSLog("Render notify stat: %d", rendernotifyStat)
			NSLog("Setting callback")
			
		}
		else
		{
			NSLog("Io unit not configured")
		}
		/*
		//get client format
		var clientFormat:AudioStreamBasicDescription = AudioStreamBasicDescription()
		//get size of CF
		let clientFormatSize = sizeof(AudioStreamBasicDescription)
		//get audio unit property for ioUnit
		AudioUnitGetProperty(<#T##AudioUnit#>, <#T##AudioUnitPropertyID#>, <#T##AudioUnitScope#>, <#T##AudioUnitElement#>, <#T##UnsafeMutablePointer<Void>#>, <#T##UnsafeMutablePointer<UInt32>#>)
		//set property for extaudiofile
		ExtAudioFileSetProperty(<#T##inExtAudioFile: ExtAudioFileRef##ExtAudioFileRef#>, <#T##inPropertyID: ExtAudioFilePropertyID##ExtAudioFilePropertyID#>, <#T##inPropertyDataSize: UInt32##UInt32#>, <#T##inPropertyData: UnsafePointer<Void>##UnsafePointer<Void>#>)
		//set ext audio file write async to file
		ExtAudioFileWriteAsync(<#T##inExtAudioFile: ExtAudioFileRef##ExtAudioFileRef#>, <#T##inNumberFrames: UInt32##UInt32#>, <#T##ioData: UnsafePointer<AudioBufferList>##UnsafePointer<AudioBufferList>#>)
		//audio unit add render notify (callback)
		AudioUnitAddRenderNotify(ioUnit, renderCallback, <#T##inProcUserData: UnsafeMutablePointer<Void>##UnsafeMutablePointer<Void>#>)
*/
	}
	
	@IBAction func stopRecording(sender : UIButton)
	{
		AudioUnitRemoveRenderNotify(self.ioUnit, renderCallback, nil)
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

