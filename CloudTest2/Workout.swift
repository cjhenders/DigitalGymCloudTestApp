//
//  Workout.swift
//  CloudTest2
//
//  Created by Carl Henderson on 7/12/16.
//  Copyright © 2016 Carl Henderson. All rights reserved.
//

import UIKit

class Workout: NSObject {
    //Mark: Properties
    
    var name: String
    var pace: [Double]
    var date: String
    
    //Data for Cloudant Sync
    var docId: String?
    var createdAt: NSDate
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("workouts")

    
    // MARK: Types
    
    struct PropertyKey {
        static let nameKey = "name"
        static let paceKey = "pace"
        static let dateKey = "date"
    }
    
    
    //Mark: Initialization
    init?(name:String, pace:[Double], date: String, docId:String?){
        self.name = name
        self.pace = pace
        self.date = date
        self.docId = docId
        self.createdAt = NSDate()
        
        super.init()
        
        if name.isEmpty || pace.count < 0 {
            return nil
        }
    }
    required convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body {
            let name = body["name"] as! String
            let pace = body["pace"] as! Array<Double>
            let date = body["date"] as! String
            

        self.init(name:name, pace:pace, date:date,
                      docId:doc.docId)
        }
        else {
            print("Error initializing meal from document: \(doc)")
            return nil
        }
    }
    
    /*//Mark: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(pace, forKey: PropertyKey.paceKey)
        // Watch this!!!!! May not be able to encode object becaus pace is an array
        aCoder.encodeObject(date, forKey: PropertyKey.dateKey)*/
    
    }
    /* required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as! String
        // Because photo is an optional property of Meal, use conditional cast.
        let pace = aDecoder.decodeObjectForKey(PropertyKey.paceKey) as? Array<Double>
        let date = aDecoder.decodeObjectForKey(PropertyKey.dateKey) as! String
        
        // Must call designated initializer.
        self.init(name: name, pace: pace!, date:date)
    */


