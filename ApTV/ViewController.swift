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

    @IBOutlet weak var dauChart: LineChartView!
    @IBOutlet weak var exceptionChart: LineChartView!
    @IBOutlet weak var carrierChart: PieChartView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var exceptionData:NSArray = []
    var crashData:NSArray = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dauChart.noDataText = "Data not available"
        self.exceptionChart.noDataText = "Data not available"

        Helper.styleLineChart(self.dauChart)
        Helper.styleLineChart(self.exceptionChart)
        Helper.stylePieChart(self.carrierChart)

        NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: #selector(ViewController.updateTime), userInfo: nil, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(60*60, target:self, selector: #selector(ViewController.updateData), userInfo: nil, repeats: true)
        
        // call these, the timers wait until the interval completes to fire
        self.updateTime()
        self.updateData()
    }

    func updateTime() {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        timeLabel.text = dateFormatter.stringFromDate(NSDate())
    }

    func updateData() {
                
        let appID:String = NSUserDefaults.standardUserDefaults().objectForKey("appID") as! String
        
        Helper.getData("https://developers.crittercism.com:443/v1.0/"+appID+"/trends/dau", method: "GET", params: nil) { (json) -> Void in
            self.drawDAUChart(json as! NSDictionary)
        }
        
        Helper.getData("https://developers.crittercism.com:443/v1.0/app/"+appID+"/crash/counts", method: "GET", params: nil) { (json) -> Void in
            self.crashData = json as! NSArray
            self.updateErrorChart()
        }
        
        Helper.getData("https://developers.crittercism.com:443/v1.0/app/"+appID+"/exception/counts", method: "GET", params: nil) { (json) -> Void in
            self.exceptionData = json as! NSArray
            self.updateErrorChart()
        }

        
        let pmParams:Dictionary = [ "params": [ "appId": appID, "graph": "volume", "duration":60, "groupBy":"carrier" ]]
        Helper.getData("https://developers.crittercism.com:443/v1.0/performanceManagement/pie", method: "POST", params: pmParams, callback: { (json) -> Void in
            self.drawCarrierChart(json as! NSDictionary)
        })
    }
    
    
    func updateErrorChart() {
        
        var exceptionDataEntries: [ChartDataEntry] = []
        var crashDataEntries: [ChartDataEntry] = []
        var dates: [String] = []
        
        var dataSets: [LineChartDataSet] = []
        
        // if we have exception data, add it to the set
        if(self.exceptionData.count > 0) {
            for i in 00..<self.exceptionData.count {
                
                let bucketData:NSDictionary = self.exceptionData[i] as AnyObject! as! NSDictionary
                print(bucketData)
                let value:Int = bucketData["value"] as AnyObject! as! Int
                let dateString:String = bucketData["date"] as AnyObject! as! String
                let formattedString:String = Helper.formatDateString(dateString, format:"yyyy'-'MM'-'dd'")
                
                let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
                
                if !dates.contains(formattedString) {
                    dates.append(formattedString)
                }
                
                exceptionDataEntries.append(dataEntry)
            }
            
            var exceptionSet = LineChartDataSet(yVals: exceptionDataEntries, label: "Exceptions")
            Helper.formatDataSet(&exceptionSet, color: UIColor.orangeColor())

            dataSets.append(exceptionSet)
        }
        
        // if we have crash data, add it to the set
        if(self.crashData.count > 0) {
            for i in 00..<self.crashData.count {
                
                let bucketData:NSDictionary = self.crashData[i] as AnyObject! as! NSDictionary
                print(bucketData)
                let value:Int = bucketData["value"] as AnyObject! as! Int
                
                let dateString:String = bucketData["date"] as AnyObject! as! String
                let formattedString:String = Helper.formatDateString(dateString, format: "yyyy'-'MM'-'dd'")
                
                let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
                
                if !dates.contains(formattedString) {
                    dates.append(formattedString)
                }

                crashDataEntries.append(dataEntry)
            }

            
            var crashSet = LineChartDataSet(yVals: crashDataEntries, label: "Crashes")
            let setColor = UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255)
            Helper.formatDataSet(&crashSet, color: setColor)

            dataSets.append(crashSet)
        }
        
        self.exceptionChart.data = LineChartData(xVals: dates, dataSets: dataSets)
    }
    
    func drawDAUChart(jsonDict: NSDictionary) {
        
        let series:NSDictionary = jsonDict["series"] as AnyObject! as! NSDictionary
        let buckets:NSArray = series["buckets"] as AnyObject! as! NSArray
        
        var dataEntries: [ChartDataEntry] = []
        var dates: [String] = []
        
        for i in 0..<buckets.count {
            let bucketData:NSDictionary = buckets[i] as AnyObject! as! NSDictionary
            print(bucketData)
            let value:Int = bucketData["value"] as AnyObject! as! Int
            let dateString:String = bucketData["start"] as AnyObject! as! String
            print(dateString)
            let formattedString:String = Helper.formatDateString(dateString, format: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ")
            
            let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
            
            dates.append(formattedString)
            dataEntries.append(dataEntry)
        }
        
        var chartDataSet = LineChartDataSet(yVals: dataEntries, label: "Active Users")
        let dataColor = UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255)
        
        Helper.formatDataSet(&chartDataSet, color: dataColor)
        
        dauChart.data = LineChartData(xVals: dates, dataSet: chartDataSet)
    }
    
    func drawCarrierChart(jsonDict: NSDictionary) {
        
        let series:NSDictionary = jsonDict["data"] as AnyObject! as! NSDictionary
        let buckets:NSArray = series["slices"] as AnyObject! as! NSArray
        
        var dataEntries: [ChartDataEntry] = []
        var carriers: [String] = []
        
        
        // pre-process and sort our data
        var processedData:Dictionary = [ "other": 0 ]
        for i in 0..<buckets.count {
            
            let bucketData:NSDictionary = buckets[i] as AnyObject! as! NSDictionary
            print(bucketData)
            let value:Int = bucketData["value"] as AnyObject! as! Int
            let carrierString:String = bucketData["label"] as AnyObject! as! String
            processedData[carrierString] = value
        }
        
        let myArray = Array(processedData.keys)
        let sortedKeys = myArray.sort() {
            let obj1 = processedData[$0] // get ob associated w/ key 1
            let obj2 = processedData[$1] // get ob associated w/ key 2
            return obj1 > obj2
        }

        // now we want to make sure we only have a max 5 keys
        for i in 0..<5 {
            if (sortedKeys.count <= i) { break }
            
            let dataEntry = BarChartDataEntry(value: Double(processedData[sortedKeys[i]]!), xIndex: i)
            carriers.append(sortedKeys[i])
            dataEntries.append(dataEntry)
        }
        
        // add 'other'
        var otherValue = 0
        if(sortedKeys.count > 5) {
            
            for i in 5..<sortedKeys.count {
                otherValue += processedData[sortedKeys[i]]!
            }
        
            let dataEntry = BarChartDataEntry(value: Double(otherValue), xIndex: 5)
            carriers.append("Other")
            dataEntries.append(dataEntry)
        }

        
        var chartDataSet = PieChartDataSet(yVals: dataEntries, label: "Carriers")
        Helper.formatPieData(&chartDataSet)
        
        self.carrierChart.data = PieChartData(xVals: carriers, dataSet: chartDataSet)
    }
}

