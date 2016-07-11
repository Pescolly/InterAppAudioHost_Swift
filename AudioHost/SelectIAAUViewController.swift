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
	func selectIAAUViewController(viewController:SelectIAAUViewController, didSelectUnit audioUnit:InterAppAudioUnit)
	func selectIAAUViewControllerWantsToClose(viewController: SelectIAAUViewController)
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
		                                                        style: .Plain,
		                                                        target: self,
		                                                        action: "closeTapped:")
		
		self.tableView .registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
		
		self.refreshList()
		
		// Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

	func closeTapped(sender: AnyObject)
	{
		self.delegate?.selectIAAUViewControllerWantsToClose(self)
	}
	
	init (withSearchDescription:AudioComponentDescription)
	{
		super.init(style: UITableViewStyle.Plain)
		self.searchDescription = withSearchDescription
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	func refreshList()
	{
		let unitss = NSMutableArray()
		var component:AudioComponent = nil
		while (true)
		{

			component = AudioComponentFindNext(component, &self.searchDescription)
			if component == nil
			{
				break;
			}
			
			var desc:AudioComponentDescription = AudioComponentDescription()
			let err = AudioComponentGetDescription(component, &desc)
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
				unit.icon = AudioComponentGetIcon(component, 44.0)
				unit.component = component
				
				var name:Unmanaged<CFString>?
				let stat = AudioComponentCopyName(component, &name)
				
				if (name != nil)
				{
					//	let nameString:String = name!.toOpaque() as! CFStringRef as String
					unit.name = name.debugDescription
					unitss.addObject(unit)
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
	
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        // #warning Incomplete implementation, return the number of rows
        return units.count
    }
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell 
	{
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

		let unit:InterAppAudioUnit = self.units[indexPath.row] as! InterAppAudioUnit
		cell.imageView?.image = unit.icon
		cell.textLabel?.text = unit.name
		
        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		let unit = self.units[indexPath.row]
		delegate?.selectIAAUViewController(self, didSelectUnit: unit as! InterAppAudioUnit)
	}
	

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
