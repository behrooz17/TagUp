//
//  TagsViewController.swift
//  TagUp
//
//  Created by Behrooz Amuyan on 4/27/16.
//  Copyright © 2016 Behrooz. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Charts


class TagsViewController: UIViewController, UITableViewDataSource {
    var tags   : [JSON]!
    var colors : [JSON]!
    
    // variables for the Tags info
    var arrayTags:[String]      = []
    var arrayConfs:[Int]        = []
    var arrayTagsGraph:[String] = []
    var arrayConfsGraph: [Int]  = []
    // variables for the Color info
    var arrayColors:[String]    = []
    var arrayPercentage:[Int]   = []
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var SegmentedControl: UISegmentedControl!
    @IBOutlet weak var barChartView: BarChartView!
    
    // Controlling the charts depending on the segment controlled selection.
    @IBAction func tagsColorsSegmentController(sender: UISegmentedControl) {
        
        tableView.reloadData()
        barChartView.reloadInputViews()
        if SegmentedControl.selectedSegmentIndex == 0 {
            setChart(arrayTagsGraph, values: arrayConfsGraph)
        }
        else {
        setChart(arrayColors, values: arrayPercentage)
        }
    }
    // MARK: - Bar Chart
    // creating the bar chart. https://github.com/danielgindi/Charts
    func setChart(dataPoints: [String], values: [Int]) {
        
        let arrayLn = dataPoints
        var xValue:[String] = []
        var yValue:[Int] = []
        var chartLabel = ""
        var desc = ""
        if SegmentedControl.selectedSegmentIndex == 0 {
             xValue = arrayTagsGraph
             yValue = arrayConfsGraph
             chartLabel = "Tags (Top 3)"
             desc = "Confidence"
        }
        else if SegmentedControl.selectedSegmentIndex == 1 {
            xValue = arrayColors
            yValue = arrayPercentage
            chartLabel = "Colors(%)"
            desc = "Percentage"
        }
        barChartView.noDataText = "You need to provide data for the chart."
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<arrayLn.count {
        
            let dataEntry = BarChartDataEntry(value: Double(yValue[i]), xIndex: i)
            
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: chartLabel)
        
        let chartData = BarChartData(xVals: xValue, dataSet: chartDataSet)
        
        // changing the bar color
        chartDataSet.colors = [UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5)]
        barChartView.data = chartData
        barChartView.xAxis.labelPosition = .Bottom
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        barChartView.descriptionText = desc
    }
    
     // MARK: - Table view data source
    // depending on which segment controller has been selected , displayes the corresponding data in table view.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var data = 0
        switch ( SegmentedControl.selectedSegmentIndex) {
        case 0 :
            data = tags.count
            break
        case 1:
            data = colors.count
            break
        default:
            break
        }
        return data
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TagsTableViewCell") as! TagsTableViewCell
        
        // serializing data - getting the tag and confidence
        switch (SegmentedControl.selectedSegmentIndex) {
        case 0 :
            let tagsData = tags[indexPath.row]["tag"].stringValue
            let confData = tags[indexPath.row]["confidence"].intValue
            cell.lblTagCell.text = tagsData
            cell.lblConfCell.text = String(confData)
            cell.colorViewCell.hidden = true
            break
        case 1 :
            let colorData = colors[indexPath.row]["closest_palette_color"].stringValue
            let codeData = colors[indexPath.row]["html_code"].stringValue
            cell.lblTagCell.text = colorData
            cell.lblConfCell.text = codeData
            cell.colorViewCell.hidden = false
            // getting the RGB data and coloring the color view cell
            let red = colors[indexPath.row]["r"].intValue
            let blue = colors[indexPath.row]["b"].intValue
            let green = colors[indexPath.row]["g"].intValue
            cell.colorViewCell.backgroundColor = UIColor(
                    red: CGFloat(red)/255.0,
                    green: CGFloat(green)/255.0,
                    blue: CGFloat(blue)/255.0,
                    alpha: 1.0)

            break
        default :
            break
        }
        
        return cell
    }
    
    
    // MARK: - ViewDIdLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        //let confData = tags[0]["confidence"].stringValue
        
        
//        let sortedTags = tags.sort { (elem1, elem2) -> Bool in
//            return elem1["confidence"].doubleValue < elem2["confidence"].doubleValue
//        }
//        
//        let limitedTags = sortedTags[0...4]
//        print ( "limited tags is \(limitedTags)")
        
        // creates arrayTags and arrayConfs with elements of each values to be used in the bar chart.
        arrayTags = tags.map { tag in
            return tag["tag"].stringValue
        }
      
        arrayConfs = tags.map({ tag in
            return tag["confidence"].intValue
        })
        
        arrayColors = colors.map { colors in
            return colors["closest_palette_color"].stringValue
        }
        arrayPercentage = colors.map { colors in
            return colors["percentage"].intValue
        }
        
//        for var i = 0; i < 5 ; i++ {
//            
//
//            arrayTags.append(tags[i]["tag"].stringValue)
//            arrayConfs.append(tags[i]["confidence"].intValue)
//            
//        }
        // takes the top 3 tags.
        for var i = 0; i < 3; i++ {
            arrayTagsGraph.append(arrayTags[i])
            arrayConfsGraph.append(arrayConfs[i])
        }
        
        print ("arrayConfsGraph = \(arrayConfsGraph)")
        print ("arrayTagsGraph = \(arrayTagsGraph)")
        
        print ("arrayColors = \(arrayColors)")
        print ("arrayPercentage = \(arrayPercentage)")
        // upon load both garphs are loaded
        if SegmentedControl.selectedSegmentIndex == 0 {
            setChart(arrayTagsGraph, values: arrayConfsGraph)
        }
        else {
            setChart(arrayColors, values: arrayPercentage)
        }
        
    }

}
