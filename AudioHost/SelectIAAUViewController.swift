//
//  SelectIAAUViewController.swift
//  AudioHost
//
//  Created by armen karamian on 6/30/16.
//  Copyright © 2016 armen karamian. All rights reserved.
//

import UIKit
import AudioUnit
import AudioToolbox

protocol SelectIAAUViewControllerDelegate
{
	func selectIAAUViewController(_ viewController:SelectIAAUViewController, didSelectUnit audioUnit:InterAppAudioUnit)
	func selectIAAUViewControllerWantsToClose(_ viewController: SelectIAAUViewController)
}

class SelectIAAUViewController: UITableViewController
{
	var delegate:SelectIAAUViewControllerDelegate?
	var searchDescription:AudioComponentDescription = AudioComponentDescription()
	var units:NSArray = NSArray()
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
		                                                        style: .plain,
		                                                        target: self,
		                                                        action: #selector(SelectIAAUViewController.closeTapped(_:)))
		
		self.tableView .register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
		
		self.refreshList()
		
		// Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

	func closeTapped(_ sender: AnyObject)
	{
		self.delegate?.selectIAAUViewControllerWantsToClose(self)
	}
	
	init (withSearchDescription:AudioComponentDescription)
	{
		super.init(style: UITableViewStyle.plain)
		self.searchDescription = withSearchDescription
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	func refreshList()
	{
		let unitss = NSMutableArray()
		var component:AudioComponent? = nil
		while (true)
		{

			component = AudioComponentFindNext(component, &self.searchDescription)
			if component == nil
			{
				break;
			}
			
			var desc:AudioComponentDescription = AudioComponentDescription()
			let err = AudioComponentGetDescription(component!, &desc)
			if (desc.componentType == kAudioUnitType_RemoteInstrument ||
			desc.componentType == kAudioUnitType_RemoteGenerator )
			{
				if err != noErr
				{
					NSLog("Err in refresh list")
					continue
				}
				
				let unit:InterAppAudioUnit = InterAppAudioUnit()
				unit.compDescription = desc
				unit.icon = AudioComponentGetIcon(component!, 44.0)
				unit.component = component
				
				var name:Unmanaged<CFString>?
				let stat = AudioComponentCopyName(component!, &name)
				
				if (name != nil)
				{
					//	let nameString:String = name!.toOpaque() as! CFStringRef as String
					unit.name = name.debugDescription
					unitss.add(unit)
				}
			}
		}
		
		self.units = unitss
		self.tableView.reloadData()
	}
	
    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    override func numberOfSections(in tableView: UITableView) -> Int
	{
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        // #warning Incomplete implementation, return the number of rows
        return units.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell 
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let unit:InterAppAudioUnit = self.units[(indexPath as NSIndexPath).row] as! InterAppAudioUnit
		cell.imageView?.image = unit.icon
		cell.textLabel?.text = unit.name
		
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let unit = self.units[(indexPath as NSIndexPath).row]
		delegate?.selectIAAUViewController(self, didSelectUnit: unit as! InterAppAudioUnit)
	}

}
