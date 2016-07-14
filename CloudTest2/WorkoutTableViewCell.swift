//
//  WorkoutTableViewCell.swift
//  CloudTest2
//
//  Created by Carl Henderson on 7/12/16.
//  Copyright © 2016 Carl Henderson. All rights reserved.
//

import UIKit

class WorkoutTableViewCell: UITableViewCell {
    
    //Mark: Properties
    @IBOutlet weak var workoutLabel: UILabel!
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
