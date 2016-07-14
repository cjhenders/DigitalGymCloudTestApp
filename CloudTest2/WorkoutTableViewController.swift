//
//  WorkoutTableViewController.swift
//  CloudTest2
//
//  Created by Carl Henderson on 7/12/16.
//  Copyright © 2016 Carl Henderson. All rights reserved.
//

import UIKit

class WorkoutTableViewController: UITableViewController, CDTHTTPInterceptor, CDTReplicatorDelegate {
    
    //Mark: Properties
    
    var workouts = [Workout]()
    var datastoreManager: CDTDatastoreManager?
    var datastore: CDTDatastore?
    
    // Define two sync directions: push and pull.
    // .Push will copy local data from FoodTracker to Cloudant.
    // .Pull will copy remote data from Cloudant to FoodTracker.
    enum SyncDirection {
        case Push
        case Pull
    }
    
    // Track pending .Push and .Pull replications here.
    var replications = [SyncDirection: CDTReplicator]()
    
    //Mark: Cloudant Settings
    let userAgent = "FoodTracker"
    
    let cloudantDBName = "workout_tracker"
    
    // NOTE: You must change these values for your own application.
    let cloudantAccount = "cjhenders"
    let cloudantApiKey = "maducesseleastainguender"
    let cloudantApiPassword = "344fb73532636a1c04e058b61401e3696ff1a908"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.viewDidLoad()
        
        // Activate the pull-to-refresh control.
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action:
            #selector(WorkoutTableViewController.handleRefresh(_:)),
                                       forControlEvents: UIControlEvents.ValueChanged)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Initialize the Cloudant Sync local datastore.
        initDatastore()
        
        sync(.Push)
    }
    
    /*func loadSampleWorkouts(){
        
        let workout1 = Workout(name: "Workout 1", pace: [67.0,68.0,69.0,65.0,68.0,67.0,56.0,66.0,59.0,75.0], date: "July 12th 2016")
        let workout2 = Workout(name: "Workout 2", pace: [45.0,55.0,49.0,48.0,46.0,48.0,57.0,76.0,34.0,35.0], date: "July 13th 2016")
        
        workouts += [workout1!, workout2!]
    }*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "WorkoutTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! WorkoutTableViewCell
        
        // Fetches the appropriate meal for the data source layout.
        let workout = workouts[indexPath.row]
        
        cell.workoutLabel.text = workout.name
        cell.dateLabel.text = workout.date
        
        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let workout = workouts[indexPath.row]
            deleteWorkout(workout)
            workouts.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            // Push this deletion to Cloudant.
            sync(.Push)
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let workoutDetailViewController = segue.destinationViewController as! WorkoutViewController
            
            // Get the cell that generated this segue.
            if let selectedMealCell = sender as? WorkoutTableViewCell{
                let indexPath = tableView.indexPathForCell(selectedMealCell)!
                let selectedMeal = workouts[indexPath.row]
                workoutDetailViewController.workout = selectedMeal
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new workout .")
        }
    }

    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? WorkoutViewController, workout = sourceViewController.workout {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                workouts[selectedIndexPath.row] = workout
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                updateWorkout(workout)
            }
            else {
                // Add a new meal.
                let newIndexPath = NSIndexPath(forRow: workouts.count, inSection: 0)
                workouts.append(workout)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
                createWorkout(workout)
                
                // Push this edit or creation to Cloudant.
                sync(.Push)
                
        }
    }
}
    // MARK: Datastore
    
    func initDatastore() {
        let fileManager = NSFileManager.defaultManager()
        
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
                                                        inDomains: .UserDomainMask).last!
        
        let storeURL = documentsDir.URLByAppendingPathComponent("WorkoutTracker-workouts")
        let path = storeURL.path
        
        do {
            datastoreManager = try CDTDatastoreManager(directory: path)
            datastore = try datastoreManager!.datastoreNamed("workouts")
        } catch {
            fatalError("Failed to initialize datastore: \(error)")
        }
        storeSampleWorkouts()
        datastore?.ensureIndexed(["created_at"], withName: "timestamps")
        
        // Everything is ready. Load all meals from the datastore.
        loadWorkoutsFromDatastore()
        
        // Immediately pull changes from Cloudant.
        sync(.Pull)
    }
    func populateRevision(workout: Workout, revision: CDTDocumentRevision?) {
        // Populate a document revision from a Meal.
        let rev: CDTDocumentRevision = revision
            ?? CDTDocumentRevision(docId: workout.docId)
        rev.body["name"] = workout.name
        rev.body["date"] = workout.date
        rev.body["pace"] = workout.pace
        
        // Set created_at as an ISO 8601-formatted string.
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let createdAtISO = dateFormatter.stringFromDate(workout.createdAt)
        rev.body["created_at"] = createdAtISO
        
        
        
    }
    // Create a meal. Return true if the meal was created, or false if
    // creation was unnecessary.
    func createWorkout(workout: Workout) -> Bool {
        // User-created meals will have docId == nil. Sample meals have a
        // string docId. For sample meals, look up the existing doc, with
        // three possible outcomes:
        //   1. No exception; the doc is already present. Do nothing.
        //   2. The doc was created, then deleted. Do nothing.
        //   3. The doc has never been created. Create it.
        if let docId = workout.docId {
            do {
                try datastore!.getDocumentWithId(docId)
                print("Skip \(docId) creation: already exists")
                return false
            } catch let error as NSError {
                if (error.userInfo["NSLocalizedFailureReason"] as? String
                    != "not_found") {
                    print("Skip \(docId) creation: already deleted by user")
                    return false
                }
                
                print("Create sample workout: \(docId)")
            }
        }
        
        let rev = CDTDocumentRevision(docId: workout.docId)
        populateRevision(workout, revision: rev)
        
        do {
            let result = try datastore!.createDocumentFromRevision(rev)
            print("Created \(result.docId) \(result.revId)")
            
            workout.docId = result.docId
        } catch {
            print("Error creating meal: \(error)")
        }
        
        return true
    }
    func deleteWorkout(workout: Workout) {
        updateWorkout(workout, isDelete: true)
    }
    
    func updateWorkout(workout: Workout) {
        updateWorkout(workout, isDelete: false)
    }
    
    func updateWorkout(workout: Workout, isDelete: Bool) {
        guard let docId = workout.docId else {
            print("Cannot update a meal with no document ID")
            return
        }
        
        let label = isDelete ? "Delete" : "Update"
        print("\(label) \(docId): begin")
        
        // First, fetch the current document revision from the DB.
        var rev: CDTDocumentRevision
        do {
            rev = try datastore!.getDocumentWithId(docId)
            populateRevision(workout, revision: rev)
        } catch {
            print("Error loading meal \(docId): \(error)")
            return
        }
        
        do {
            var result: CDTDocumentRevision
            if (isDelete) {
                result = try datastore!.deleteDocumentFromRevision(rev)
            } else {
                result = try datastore!.updateDocumentFromRevision(rev)
            }
            
            print("\(label) \(docId) ok: \(result.revId)")
        } catch {
            print("Error updating \(docId): \(error)")
            return
        }
    }
    func loadWorkoutsFromDatastore() {
        let query = ["created_at": ["$gt":""]]
        let result = datastore?.find(query, skip: 0, limit: 0, fields:nil, sort: [["created_at":"asc"]])
        guard result != nil else {
            print("Failed to query for meals")
            return
        }
        
        workouts.removeAll()
        result!.enumerateObjectsUsingBlock({ (doc, idx, stop) -> Void in
            if let workout = Workout(aDoc: doc) {
                self.workouts.append(workout)
            }
    })
    }
    func storeSampleWorkouts() {
        
        let workout1 = Workout(name: "Workout 1", pace: [67.0,68.0,69.0,65.0,68.0,67.0,56.0,66.0,59.0,75.0], date: "July 12th 2016", docId:  "Workout2")!
        let workout2 = Workout(name: "Workout 2", pace: [45.0,55.0,49.0,48.0,46.0,48.0,57.0,76.0,34.0,35.0], date: "July 13th 2016", docId: "Workout1")!
        let workout3 = Workout(name: "Workout 3", pace: [45.0,25.0,49.0,42.0,46.0,54.0,57.0,76.0,34.0,35.0], date: "July 14th 2016", docId: "Workout3")!

        
        // Hard-code the createdAt property to get consistent revision IDs. That way, devices that share
        // a common cloud database will not generate conflicts as they sync their own sample meals.
        let comps = NSDateComponents()
        comps.day = 1
        comps.month = 1
        comps.year = 2016
        comps.timeZone = NSTimeZone(abbreviation: "GMT")
        let newYear = NSCalendar.currentCalendar()
            .dateFromComponents(comps)!
        
        let created1 = createWorkout(workout1)
        let created2 = createWorkout(workout2)
        let created3 = createWorkout(workout3)
        
        if (created1 || created2 || created3) {
            print("Sample workouts changed; begin push sync")
            sync(.Push)
        }
    }
    // MARK: Cloudant Sync
    
    // Intercept HTTP requests and set the User-Agent header.
    func interceptRequestInContext(context: CDTHTTPInterceptorContext)
        -> CDTHTTPInterceptorContext {
            let info = NSBundle.mainBundle().infoDictionary!
            let appVer = info["CFBundleShortVersionString"]
            let osVer = NSProcessInfo().operatingSystemVersionString
            let ua = "\(userAgent)/\(appVer) (iOS \(osVer)"
            
            context.request.setValue(ua, forHTTPHeaderField: "User-Agent")
            return context
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        print("Pull to refresh!")
        sync(.Pull)
    }
    
    // Return an NSURL to the database, with authentication.
    func cloudURL() -> NSURL {
        let credentials = "\(cloudantApiKey):\(cloudantApiPassword)"
        let host = "\(cloudantAccount).cloudant.com"
        let url = "https://\(credentials)@\(host)/\(cloudantDBName)"
        
        return NSURL(string: url)!
    }
    
    // Push or pull local data to or from the central cloud.
    func sync(direction: SyncDirection) {
        let existingReplication = replications[direction]
        guard existingReplication == nil else {
            print("Ignore \(direction) replication; already running")
            return
        }
        
        let factory = CDTReplicatorFactory(
            datastoreManager: datastoreManager)
        
        let job = (direction == .Push)
            ? CDTPushReplication(source: datastore!, target: cloudURL())
            : CDTPullReplication(source: cloudURL(), target: datastore!)
        job.addInterceptor(self)
        
        do {
            // Ready: Create the replication job.
            replications[direction] = try factory.oneWay(job)
            
            // Set: Assign myself as the replication delegate.
            replications[direction]!.delegate = self
            
            // Go!
            try replications[direction]!.start()
        } catch {
            print("Error initializing \(direction) sync: \(error)")
            return
        }
        
        print("Started \(direction) sync: \(replications[direction])")
    }
    func replicatorDidChangeState(replicator: CDTReplicator!) {
        // The new state is in replicator.state.
    }
    
    func replicatorDidChangeProgress(replicator: CDTReplicator!) {
        // See replicator.changesProcessed and replicator.changesTotal
        // for progress data.
    }
    
    func replicatorDidComplete(replicator: CDTReplicator!) {
        print("Replication complete \(replicator)")
        
        if (replicator == replications[.Pull]) {
            if (replicator.changesProcessed > 0) {
                // Reload the meals, and refresh the UI.
                loadWorkoutsFromDatastore()
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            // End the refresh spinner, if necessary.
            self.refreshControl?.endRefreshing()
        }
        
        clearReplicator(replicator)
    }
    
    func replicatorDidError(replicator: CDTReplicator!, info:NSError!) {
        print("Replicator error \(replicator) \(info)")
        clearReplicator(replicator)
    }
    
    func clearReplicator(replicator: CDTReplicator!) {
        // Determine the replication direction, given the replicator
        // argument.
        let direction = (replicator == replications[.Push])
            ? SyncDirection.Push
            : SyncDirection.Pull
        
        print("Clear replication: \(direction)")
        replications[direction] = nil
    }
}
