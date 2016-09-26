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

var extAudioFile : ExtAudioFileRef?  = nil

let renderCallback : AURenderCallback? = {
	(indata, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> Int32 in
	print ("in callback: ", fileURL)
	NSLog("in number frames: %d", inNumberFrames)
	
	if (inBusNumber == 0 && ioActionFlags.pointee == AudioUnitRenderActionFlags.unitRenderAction_PostRender)
	{
		ioData?.pointee.mNumberBuffers = 1
		let extaudiowrite = ExtAudioFileWriteAsync(extAudioFile!, inNumberFrames, ioData)
		NSLog("ext audio write stat: %d", extaudiowrite)
	}
	
	return noErr
}

class ViewController: UIViewController, SelectIAAUViewControllerDelegate
{
	var connectedInstrument:Bool = false
	var instrumentUnit:AudioUnit? = nil
	var instrumentNode:AUNode = AUNode()
	var effectNode:AUNode?
	var connectedEffect:Bool?
	var effectUnit:AudioUnit?
	var ioNode = AUNode()
	var ioUnit:AudioUnit? = nil
	var format = AudioStreamBasicDescription()
	
	@IBOutlet var instrumentIconImageView:UIImageView?
	@IBOutlet var effectIconImageView:UIImageView?
	
	
	var graphStarted:Bool = false
	var audioGraph:AUGraph? = nil
	var _instrumentSelectViewController:SelectIAAUViewController?
	var _effectSelectViewController:SelectIAAUViewController?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		createAUGraph()
		
		print("writing to file: \(fileURL)")
		
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
		
		var extAudioFile:ExtAudioFileRef? = nil
		let filecreatestat = ExtAudioFileCreateWithURL(fileURL as CFURL, kAudioFileCAFType, &self.format, nil, 1, &extAudioFile)
		let fileopenstat = ExtAudioFileOpenURL(fileURL as CFURL, &extAudioFile)

		if filecreatestat == noErr && fileopenstat == noErr
		{
			NSLog("file created")
		}
		else
		{
			NSLog("Cannot create file")
		}
	}
	
	//protocols

	
	func selectIAAUViewControllerWantsToClose(_ viewController: SelectIAAUViewController)
	{
		self.dismiss(animated: true, completion: nil)
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
			AUGraphAddNode(self.audioGraph!, &ioUnitDescription, &self.ioNode)
			
			AUGraphOpen(self.audioGraph!)
			
			AUGraphNodeInfo(self.audioGraph!, self.ioNode, nil, &self.ioUnit)
			

			
			AudioUnitSetProperty(self.ioUnit!,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Output,
			                     1,
			                     &format,
			                     UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
			
			AudioUnitSetProperty(self.ioUnit!,
			                     kAudioUnitProperty_StreamFormat,
			                     kAudioUnitScope_Input,
			                     0,
			                     &format,
			                     UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
			
			CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph!))
			
			
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
			try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
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
			AUGraphIsInitialized(audioGraph!, &outIsInit)
			if !outIsInit.boolValue
			{
				AUGraphInitialize(audioGraph!)
			}
			
			AUGraphStart(audioGraph!)
			NSLog("Graph is initialized and started")
			graphStarted = true
		}
	}
	
	func stopAUGraph()
	{
		if graphStarted && audioGraph != nil
		{
			AUGraphStop(audioGraph!)
			var outIsInit:DarwinBoolean = false
			AUGraphIsInitialized(audioGraph!, &outIsInit)
			if outIsInit.boolValue
			{
				AUGraphUninitialize(audioGraph!)
			}
			
			graphStarted = false
		}
	}
	
	@IBAction func selectInstrument(_ sender : AnyObject)
	{
		let description : AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_RemoteInstrument,
		                                                                        componentSubType: 0,
		                                                                        componentManufacturer: 0,
		                                                                        componentFlags: 0,
		                                                                        componentFlagsMask: 0)
		
		self._instrumentSelectViewController = SelectIAAUViewController(withSearchDescription: description)
		self._instrumentSelectViewController?.delegate = self
		
		let navController:UINavigationController = UINavigationController(rootViewController: self._instrumentSelectViewController!)
		self.present(navController, animated: true, completion: nil)
	}
	
	func selectIAAUViewController(_ viewController:SelectIAAUViewController, didSelectUnit audioUnit:InterAppAudioUnit)
	{
		self.dismiss(animated: true, completion: nil)
		if (viewController == _instrumentSelectViewController)
		{
			self.connectInstrument(audioUnit)
		}
	}
	
	func connectInstrument(_ unit : InterAppAudioUnit)
	{
		NSLog("instrument selected")
		
		self.stopAUGraph()
		
		if self.instrumentNode != 0
		{
			AUGraphDisconnectNodeInput(self.audioGraph!, self.instrumentNode, 0)
			AUGraphRemoveNode(self.audioGraph!, self.instrumentNode)
			self.instrumentIconImageView?.image = nil
			self.instrumentUnit = nil
		}

		var desc : AudioComponentDescription = unit.compDescription!
		AUGraphAddNode(self.audioGraph!, &desc, &self.instrumentNode)
		AUGraphNodeInfo(self.audioGraph!, self.instrumentNode, nil, &self.instrumentUnit)
		AUGraphConnectNodeInput(self.audioGraph!, self.instrumentNode, 0, self.ioNode, 0)
	
		var maxFrames = 4096;
		let status = AudioUnitSetProperty(self.instrumentUnit!,
		                              kAudioUnitProperty_MaximumFramesPerSlice,
		                              kAudioUnitScope_Output,
		                              0,
		                              &maxFrames,
		                              UInt32(MemoryLayout<UInt32>.size));

		self.connectedInstrument = true
		self.instrumentIconImageView!.image = unit.icon
		
		self.startStopGraphAsRequired()
		CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph!))
		
	}
	
	@IBAction func playNote(_ sender : AnyObject)
	{
		if self.connectedInstrument
		{
			let noteOnCommand:UInt32 = (0x9 << 4) | 0
			MusicDeviceMIDIEvent(self.instrumentUnit!, noteOnCommand, 60, 100, 0)
			
			let delayInSeconds:UInt64 = 2
			let popTime:DispatchTime = DispatchTime.now() + Double(Int64((delayInSeconds * NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
			
			DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
				() in
				if self.connectedInstrument
				{
					let noteOffCommand:UInt32 = (0x8 << 4) | 0
					MusicDeviceMIDIEvent(self.instrumentUnit!, noteOffCommand, 60, 100, 0)
				}
			})
		}
	}
	
	
	@IBAction func record(_ sender : UIButton)
	{
		let openfilestat = ExtAudioFileOpenURL(fileURL as CFURL, &extAudioFile)
		if openfilestat != 0 { print ("err: \(openfilestat)") }
		//record ioUnit input using callback
		if self.ioUnit != nil
		{
			CAShow(UnsafeMutablePointer<AUGraph>(self.audioGraph!))
			var inputCallback : AURenderCallbackStruct = AURenderCallbackStruct(inputProc: renderCallback, inputProcRefCon: nil)
			let rendernotifyStat : OSStatus = AudioUnitAddRenderNotify(self.ioUnit!, renderCallback!, nil)
			NSLog("Render notify stat: %d", rendernotifyStat)
			NSLog("Setting callback")
		}
		else { NSLog("Io unit not configured") }
	}
	
	@IBAction func stopRecording(_ sender : UIButton)
	{
		AudioUnitRemoveRenderNotify(self.ioUnit!, renderCallback!, nil)
		
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

