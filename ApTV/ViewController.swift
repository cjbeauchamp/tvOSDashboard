//
//  ViewController.swift
//  ApTV
//
//  Created by Chris Beauchamp on 3/17/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {

    // code representations of UI elements
    @IBOutlet weak var dauChart: LineChartView!
    @IBOutlet weak var exceptionChart: LineChartView!
    @IBOutlet weak var carrierChart: PieChartView!
    @IBOutlet weak var timeLabel: UILabel!
    
    // hold the exception/crash counts while 
    // they are loaded asynchronously
    var exceptionData:NSArray = []
    var crashData:NSArray = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // do some extra initialization of our chart views
        // to style them to look nice!
        Helper.styleLineChart(self.dauChart)
        Helper.styleLineChart(self.exceptionChart)
        Helper.stylePieChart(self.carrierChart)

        // fire each second to update the time label
        NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: #selector(ViewController.updateTime), userInfo: nil, repeats: true)
        
        // fire each hour to pull the data from the APIs
        NSTimer.scheduledTimerWithTimeInterval(60*60, target:self, selector: #selector(ViewController.updateData), userInfo: nil, repeats: true)
        
        // the timers wait for the interval to expire before firing for
        // the first time, so call them on load here
        self.updateTime()
        self.updateData()
    }

    // called by the time update timer to get the current time
    // and display it within the UI
    func updateTime() {
        
        // get a date formatter to show in a readable format
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        // set the UI component to the current formatted time
        timeLabel.text = dateFormatter.stringFromDate(NSDate())
    }

    func updateData() {
        
        // Get the Apteligent App ID for the app data we want to grab from the API.
        // This is stored in the NSUserDefaults
        let appID:String = NSUserDefaults.standardUserDefaults().objectForKey("appID") as! String
        
        // get the latest DAU counts for our app and draw the results once received
        Helper.getData("https://developers.crittercism.com:443/v1.0/"+appID+"/trends/dau", method: "GET", params: nil) { (json) -> Void in
            self.drawDAUChart(json as! NSDictionary)
        }
        
        // get the latest crash counts for our app and draw the results once received
        Helper.getData("https://developers.crittercism.com:443/v1.0/app/"+appID+"/crash/counts", method: "GET", params: nil) { (json) -> Void in
            // store the json as a class variable for 
            // updateErrorChart to utilize asynchronously
            self.crashData = json as! NSArray
            self.updateErrorChart()
        }
        
        // get the latest crash counts for our app and draw the results once received
        Helper.getData("https://developers.crittercism.com:443/v1.0/app/"+appID+"/exception/counts", method: "GET", params: nil) { (json) -> Void in
            // store the json as a class variable for
            // updateErrorChart to utilize asynchronously
            self.exceptionData = json as! NSArray
            self.updateErrorChart()
        }
        
        // get the latest carrier data for our app and draw the results once received
        // for more info about this API call, check out the Apteligent REST docs
        let pmParams:Dictionary = [ "params": [ "appId": appID, "graph": "volume", "duration":60, "groupBy":"carrier" ]]
        Helper.getData("https://developers.crittercism.com:443/v1.0/performanceManagement/pie", method: "POST", params: pmParams, callback: { (json) -> Void in
            self.drawCarrierChart(json as! NSDictionary)
        })
    }
    
    // parses the data received from the exception & crash
    // APIs and renders the data in the exceptionChart view
    func updateErrorChart() {
        
        // some holders for our data as we parse and sort it
        var exceptionDataEntries: [ChartDataEntry] = [] // exception y-values
        var crashDataEntries: [ChartDataEntry] = [] // crash y-values
        var dates: [String] = [] // both x-values
        var dataSets: [LineChartDataSet] = [] // holds each series (this chart shows 2)
        
        // if we have exception data, add it to the set.
        // remember these are loaded asynchronously so you may
        // have crashData but no exceptionData
        if(self.exceptionData.count > 0) {
            
            // iterate each object in the json
            for i in 00..<self.exceptionData.count {
                
                // parse the json item. returns a tuple of the form
                // (value, dateString) where value == exception count
                // and dateString == the date of the given exception count.
                // think of them as y and x values respectively
                let parsedData = Helper.parseBucket(self.exceptionData[i], valueKey: "value", dateKey: "date", dateFormat: "yyyy'-'MM'-'dd'")
                
                // create an object for the charts library to process the info.
                // each dataEntry represents an x-y point on the chart
                let dataEntry = ChartDataEntry(value: Double(parsedData.value), xIndex: i)
                
                // if the date doesn't exist in the dates array, add it.
                // we don't want duplicated (which is possible if both exception
                // and crash data has already been loaded)
                if !dates.contains(parsedData.dateString) {
                    dates.append(parsedData.dateString)
                }
                
                // add this data point to the current set
                exceptionDataEntries.append(dataEntry)
            }
            
            // create the final object for the chart library to use
            var exceptionSet = LineChartDataSet(yVals: exceptionDataEntries, label: "Exceptions")
            
            // do some styling and formatting of the chart
            Helper.formatDataSet(&exceptionSet, color: UIColor.orangeColor())

            // add the data set to the chart (this will be the complete exception set, 
            // or one full line on the chart)
            dataSets.append(exceptionSet)
        }
        
        // if we have crash data, add it to the set.
        // remember these are loaded asynchronously so you may
        // have exceptionData but no crashData
        if(self.crashData.count > 0) {

            // iterate each object in the json
            for i in 00..<self.crashData.count {
                
                // parse the json item. returns a tuple of the form
                // (value, dateString) where value == crash count
                // and dateString == the date of the given crash count.
                // think of them as y and x values respectively
                let parsedData = Helper.parseBucket(self.crashData[i], valueKey: "value", dateKey: "date", dateFormat: "yyyy'-'MM'-'dd'")
                
                // create an object for the charts library to process the info.
                // each dataEntry represents an x-y point on the chart
                let dataEntry = ChartDataEntry(value: Double(parsedData.value), xIndex: i)
                
                // if the date doesn't exist in the dates array, add it.
                // we don't want duplicated (which is possible if both exception
                // and crash data has already been loaded)
                if !dates.contains(parsedData.dateString) {
                    dates.append(parsedData.dateString)
                }

                // add this data point to the current set
                crashDataEntries.append(dataEntry)
            }

            // create the final object for the chart library to use
            var crashSet = LineChartDataSet(yVals: crashDataEntries, label: "Crashes")

            // do some styling and formatting of the chart
            let setColor = UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255)
            Helper.formatDataSet(&crashSet, color: setColor)

            // add the data set to the chart (this will be the complete exception set,
            // or one full line on the chart)
            dataSets.append(crashSet)
        }
        
        // set the chart data to our newly created data series, which will draw
        // the chart itself using the passed-in data
        self.exceptionChart.data = LineChartData(xVals: dates, dataSets: dataSets)
    }

    // parses the data received from the DAU
    // APIs and renders the data in the dauChart view
    func drawDAUChart(jsonDict: NSDictionary) {
        
        // some holders for our data as we parse and sort it
        var dataEntries: [ChartDataEntry] = [] // y-values
        var dates: [String] = [] // x-values

        // extract the buckets from the JSON
        let series:NSDictionary = jsonDict["series"] as AnyObject! as! NSDictionary
        let buckets:NSArray = series["buckets"] as AnyObject! as! NSArray
        
        // iterate through the buckets
        for i in 0..<buckets.count {

            // parse the json item. returns a tuple of the form
            // (value, dateString) where value == dau count
            // and dateString == the date of the given dau count.
            // think of them as y and x values respectively
            let parsedData = Helper.parseBucket(buckets[i], valueKey: "value", dateKey: "start", dateFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ")

            // create an object for the charts library to process the info.
            // each dataEntry represents an x-y point on the chart
            let dataEntry = ChartDataEntry(value: Double(parsedData.value), xIndex: i)
            dataEntries.append(dataEntry)
            
            // add the x-value to the data set
            dates.append(parsedData.dateString)
        }
        
        // create the final object for the chart library to use
        var chartDataSet = LineChartDataSet(yVals: dataEntries, label: "Active Users")

        // do some styling and formatting of the chart
        let dataColor = UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255)
        Helper.formatDataSet(&chartDataSet, color: dataColor)
        
        // set the chart data to our newly created data series, which will draw
        // the chart itself using the passed-in data
        dauChart.data = LineChartData(xVals: dates, dataSet: chartDataSet)
    }
    
    // parses the data received from the Service Monitoring
    // APIs and renders the data in the carrierChart view
    func drawCarrierChart(jsonDict: NSDictionary) {
        
        // some holders for our data as we parse and sort it
        var dataEntries: [ChartDataEntry] = []
        var carriers: [String] = []

        // extract the slices from the JSON
        let series:NSDictionary = jsonDict["data"] as AnyObject! as! NSDictionary
        let slices:NSArray = series["slices"] as AnyObject! as! NSArray
        
        // set up the processed data dict, which will make it easier
        // to sort and format into the chart
        var processedData:Dictionary = [ "other": 0 ]
        
        // iterate through each of the API slices
        for i in 0..<slices.count {
            
            // convert it into an NSDictionary
            let sliceData:NSDictionary = slices[i] as AnyObject! as! NSDictionary
            
            // extract the carrier value
            let value:Int = sliceData["value"] as AnyObject! as! Int

            // extract the carrier name
            let carrierString:String = sliceData["label"] as AnyObject! as! String
            
            // append this carrier as a slice to the dictionary
            processedData[carrierString] = value
        }
        
        // perform an in-place sort of the processed data, so the slices are
        // sorted by value, greatest to smallest
        let sortedKeys = Array(processedData.keys).sort() {
            let obj1 = processedData[$0] // get object associated w/ key 1
            let obj2 = processedData[$1] // get object associated w/ key 2
            
            // return the comparison (greatest to smallest)
            return obj1 > obj2
        }

        // now we want to make sure we only have a max 5 keys
        // to make sure the chart is readable and meaningful
        for i in 0..<5 {
            
            // if we don't have anymore keys (ex: only 3)
            // then break the loop
            if (sortedKeys.count <= i) { break }
            
            // otherwise, create a data entry with the data value
            let dataEntry = BarChartDataEntry(value: Double(processedData[sortedKeys[i]]!), xIndex: i)
            dataEntries.append(dataEntry)

            // add the carrier name so it's associated with the current x index
            carriers.append(sortedKeys[i])
        }
        
        // there may be > 5 keys, so create a section that
        // encompasses 'other' carriers
        var otherValue = 0
        
        // if there are more than 5 keys and we need to create the other
        if(sortedKeys.count > 5) {
            
            // iterate through the *rest* of the keys, summing 
            // their values in the 'other' slice value
            for i in 5..<sortedKeys.count {
                otherValue += processedData[sortedKeys[i]]!
            }
        
            // create the 'other' slice entry
            let dataEntry = BarChartDataEntry(value: Double(otherValue), xIndex: 5)
            dataEntries.append(dataEntry)
            
            // and add a label for this slice
            carriers.append("Other")
        }

        // create the final object for the chart library to use
        var chartDataSet = PieChartDataSet(yVals: dataEntries, label: "Carriers")

        // do some styling and formatting of the chart
        Helper.formatPieData(&chartDataSet)
        
        // set the chart data to our newly created data series, which will draw
        // the chart itself using the passed-in data
        self.carrierChart.data = PieChartData(xVals: carriers, dataSet: chartDataSet)
    }
}

