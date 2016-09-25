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
	let dateFormat = DateFormatter()
	dateFormat.dateFormat = "yyyy-MM-dd-HH-mm-ss"
	let dateString = Date().timeIntervalSince1970.description
	let filename = dateString.replacingOccurrences(of: ".", with: "-") + ".caf"
	return filename
}

func GetFilenameAndExtension(_ incomingFilepath:URL)->[String?]
{
	let l = incomingFilepath.relativeString.components(separatedBy: "/")
	let file = l.last?.components(separatedBy: ".")[0]
	let ext = l.last?.components(separatedBy: ".")[1]
	let rList = [file,ext]
	return rList
}

func listFilesOnDevice() -> [String]
{
	
	let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
	let documentDirectory = paths[0]
	let manager = FileManager.default
	var retpaths = [String]()
	
	do
	{
		let allItems = try manager.contentsOfDirectory(atPath: documentDirectory)
		
		for item in allItems
		{
			NSLog(item)
			retpaths.append(documentDirectory + ("/"+item))
		}
		
	}
	catch
	{
		NSLog("Cannot load")
	}
	return retpaths
}

func GetDocumentsDirectory() -> String
{
	let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
	let documentsDirectory = paths.first
	return documentsDirectory!
}

func createURL(_ inFilename : String) -> URL
{
	let dirURL = URL(fileURLWithPath: GetDocumentsDirectory(), isDirectory: true)
	return URL(fileURLWithPath: inFilename, relativeTo: dirURL)
}

func createTempURL(_ inFilename : String) ->URL
{
	let dirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
	return URL(fileURLWithPath: inFilename, relativeTo: dirURL)
}

func getBogusURL() ->URL
{
	let dirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
	return URL(fileURLWithPath: "BOGUS_METER_FILE", relativeTo: dirURL)
}

func URLFor(_ filename : String) -> URL?
{
	if let dirs : [String] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true) as? [String]
	{
		let dir = dirs[0] //documents directory
		let path = URL(fileURLWithPath: dir, isDirectory: true)
		return path
	}
	return nil
}
