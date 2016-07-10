//
//  InterAppAudioUnit.swift
//  AudioHost
//
//  Created by armen karamian on 6/30/16.
//  Copyright © 2016 armen karamian. All rights reserved.
//

import Foundation
import AVFoundation
import AudioUnit
import UIKit

class InterAppAudioUnit : NSObject
{
	var name:String?
	var compDescription:AudioComponentDescription?
	var component:AudioComponent?
	var icon:UIImage?
}