//
//  WorkoutViewController.swift
//  CloudTest2
//
//  Created by Carl Henderson on 7/12/16.
//  Copyright © 2016 Carl Henderson. All rights reserved.
//

import UIKit
import Charts

class WorkoutViewController: UIViewController, UINavigationControllerDelegate{
    
    //Mark: Properties
    @IBOutlet weak var workoutLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    /*
     This value is either passed by `MealTableViewController` in `prepareForSegue(_:sender:)`
     or constructed as part of adding a new meal.
     */
    var workout: Workout?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let pace = workout?.pace
        let time = ["1.0","2.0","3.0","4.0","5.0","6.0","7.0","8.0","9.0","10.0"]
        
        setChart(time, values: pace!)
        
        workoutLabel.text = workout?.name
        dateLabel.text = workout?.date
    
    }
    //Mark: Navigation
    @IBAction func `return`(sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddWorkoutMode = presentingViewController is UINavigationController

        if isPresentingInAddWorkoutMode {
            dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            navigationController!.popViewControllerAnimated(true)
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender {
            /*let name = workoutLabel.text ?? ""
            let pace = pace
            let date = date
            
            // Set the meal to be passed to MealTableViewController after the
            // unwind segue.
            let docId = workout?.docId
            workout = Workout(name: name, pace: pace, date: date, docId: docId)
        }*/
        
    }
    
    //Mark: Actions
    
    }
    func setChart(dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "Units Sold")
        let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
        //pieChartView.data = pieChartData
        
        var colors: [UIColor] = []
        
        for i in 0..<dataPoints.count {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
        }
        
        pieChartDataSet.colors = colors
        
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "Pace (RPM)")
        let lineChartData = LineChartData(xVals: dataPoints,dataSet: lineChartDataSet)
        lineChartView.data = lineChartData
        
        //Mark: Chart Properties
        lineChartView.xAxis.labelPosition = .Bottom
        lineChartView.animate(xAxisDuration: 1.25, yAxisDuration: 1.25, easingOption: .EaseInCubic)
        lineChartView.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)
    }
}



