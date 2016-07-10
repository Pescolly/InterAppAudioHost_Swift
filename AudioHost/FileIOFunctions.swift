//
//  FileIOFunctions.swift
//  MarkovChainSampler
//
//  Created by armen karamian on 4/23/16.
//  Copyright © 2016 armen karamian. All rights reserved.
//

import Foundation

func getFilenameUsingDate() -> String
{
	let dateFormat = NSDateFormatter()
	dateFormat.dateFormat = "yyyy-MM-dd-HH-mm-ss"
	let dateString = NSDate().timeIntervalSince1970.description
	let filename = dateString.stringByReplacingOccurrencesOfString(".", withString: "-") + ".caf"
	return filename
}

func GetFilenameAndExtension(incomingFilepath:NSURL)->[String?]
{
	let l = incomingFilepath.relativeString!.componentsSeparatedByString("/")
	let file = l.last?.componentsSeparatedByString(".")[0]
	let ext = l.last?.componentsSeparatedByString(".")[1]
	let rList = [file,ext]
	return rList
}

func listFilesOnDevice() -> [String]
{
	
	let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
	let documentDirectory = paths[0]
	let manager = NSFileManager.defaultManager()
	var retpaths = [String]()
	
	do
	{
		let allItems = try manager.contentsOfDirectoryAtPath(documentDirectory)
		print(allItems)
		
		for item in allItems
		{
			retpaths.append(documentDirectory.stringByAppendingString("/"+item))
		}
		
	}
	catch
	{
		print("Cannot load")
	}
	return retpaths
}

func GetDocumentsDirectory() -> String
{
	let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
	let documentsDirectory = paths.first
	return documentsDirectory!
}

func createURL(inFilename : String) -> NSURL
{
	let dirURL = NSURL(fileURLWithPath: GetDocumentsDirectory(), isDirectory: true)
	return NSURL(fileURLWithPath: inFilename, relativeToURL: dirURL)
}

func createTempURL(inFilename : String) ->NSURL
{
	let dirURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
	return NSURL(fileURLWithPath: inFilename, relativeToURL: dirURL)
}

func getBogusURL() ->NSURL
{
	let dirURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
	return NSURL(fileURLWithPath: "BOGUS_METER_FILE", relativeToURL: dirURL)
}

func URLFor(filename : String) -> NSURL?
{
	if let dirs : [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
	{
		let dir = dirs[0] //documents directory
		let path = NSURL(fileURLWithPath: dir, isDirectory: true)
		return path
	}
	return nil
}