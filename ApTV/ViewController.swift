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
    
    var sessionConfig:NSURLSessionConfiguration!
    var session:NSURLSession!
    
    var appID:String = "" // demo with carrier
    var accessToken:String = "" // demo
    
    var months: [String]!
    var exceptionData:NSArray = []
    var crashData:NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.sessionConfig.HTTPAdditionalHeaders = ["Authorization": "Bearer " + self.accessToken]
        self.session = NSURLSession(configuration: self.sessionConfig)

        NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateTime"), userInfo: nil, repeats: true)

        enum JSONError: String, ErrorType {
            case NoData = "ERROR: no data"
            case ConversionFailed = "ERROR: conversion from JSON failed"
        }
        
        
        self.dauChart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        self.dauChart.xAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.dauChart.xAxis.labelTextColor = UIColor.whiteColor()
        self.dauChart.xAxis.drawAxisLineEnabled = false
        self.dauChart.xAxis.drawGridLinesEnabled = false
        
        self.dauChart.leftAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.dauChart.leftAxis.labelTextColor = UIColor.whiteColor()
        self.dauChart.leftAxis.drawAxisLineEnabled = false
        self.dauChart.rightAxis.drawAxisLineEnabled = false
        
        self.dauChart.legend.form = ChartLegend.ChartLegendForm.Line
        self.dauChart.legend.font = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.dauChart.legend.textColor = UIColor.whiteColor()
        self.dauChart.legend.position = ChartLegend.ChartLegendPosition.BelowChartCenter

        
        
        
        self.exceptionChart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        self.exceptionChart.xAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.exceptionChart.xAxis.labelTextColor = UIColor.whiteColor()
        self.exceptionChart.xAxis.drawAxisLineEnabled = false
        self.exceptionChart.xAxis.drawGridLinesEnabled = false
        
        self.exceptionChart.leftAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.exceptionChart.leftAxis.labelTextColor = UIColor.whiteColor()
        self.exceptionChart.leftAxis.drawAxisLineEnabled = false
        self.exceptionChart.rightAxis.drawAxisLineEnabled = false

        self.exceptionChart.legend.form = ChartLegend.ChartLegendForm.Line
        self.exceptionChart.legend.font = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        self.exceptionChart.legend.textColor = UIColor.whiteColor()
        self.exceptionChart.legend.position = ChartLegend.ChartLegendPosition.BelowChartCenter

        
        
        self.carrierChart.noDataText = "Data not available"
        self.carrierChart.legend.enabled = false
//        self.carrierChart.legend.form = ChartLegend.ChartLegendForm.Line
//        self.carrierChart.legend.font = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
//        self.carrierChart.legend.textColor = UIColor.whiteColor()
//        self.carrierChart.legend.position = ChartLegend.ChartLegendPosition.BelowChartCenter
        
        self.carrierChart.holeRadiusPercent = 0.3
        self.carrierChart.transparentCircleRadiusPercent = 0.35
        self.carrierChart.holeColor = UIColor.blackColor()
        self.carrierChart.transparentCircleColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        
        self.getUserData()
        self.getCarrierData()
        self.getExceptionData()
        self.getCrashData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCarrierData() {
        let endpoint = NSURL(string: "https://developers.crittercism.com:443/v1.0/performanceManagement/pie")
        let request = NSMutableURLRequest(URL:endpoint!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let params:Dictionary = [ "params": [ "appId": self.appID, "graph": "volume", "duration":60, "groupBy":"carrier" ]]
        
        do {
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options:NSJSONWritingOptions.init(rawValue: 0))
        } catch { print("Error paraming", error) }
        
        self.session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                guard let dat = data else { throw NSError(domain: "com.apteligent.JSON", code: 1, userInfo: nil) }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSDictionary else { throw NSError(domain: "com.apteligent.JSON", code: 2, userInfo: nil) }
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(),{
                    self.drawCarrierChart(json)
                })
                
            } catch {
                print("Error", error)
            }
        }.resume()
    }
    
    func getUserData() {
        let endpoint = NSURL(string: "https://developers.crittercism.com:443/v1.0/"+self.appID+"/trends/dau")
        let request = NSMutableURLRequest(URL:endpoint!)
        self.session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                guard let dat = data else { throw NSError(domain: "com.apteligent.JSON", code: 1, userInfo: nil) }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSDictionary else { throw NSError(domain: "com.apteligent.JSON", code: 2, userInfo: nil) }
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(),{
                    self.drawDAUChart(json)
                })
                
            } catch {
                print("Error", error)
            }
            }.resume()
    }
    
    func getExceptionData() {
        
        let endpoint = NSURL(string: "https://developers.crittercism.com:443/v1.0/app/"+self.appID+"/crash/counts")
        let request = NSMutableURLRequest(URL:endpoint!)
        
        self.session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                
                guard let dat = data else { throw NSError(domain: "com.apteligent.JSON", code: 1, userInfo: nil) }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSArray else { throw NSError(domain: "com.apteligent.JSON", code: 2, userInfo: nil) }
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(),{
                    self.crashData = json
                    self.updateErrorChart()
                })
                
            } catch {
                print("Error", error)
            }
            }.resume()
    }
    
    func getCrashData() {
        let endpoint = NSURL(string: "https://developers.crittercism.com:443/v1.0/app/"+self.appID+"/exception/counts")
        let request = NSMutableURLRequest(URL:endpoint!)
        self.session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                guard let dat = data else { throw NSError(domain: "com.apteligent.JSON", code: 1, userInfo: nil) }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSArray else { throw NSError(domain: "com.apteligent.JSON", code: 2, userInfo: nil) }
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(),{
                    self.exceptionData = json
                    self.updateErrorChart()
                })
                
            } catch {
                print("Error", error)
            }
            }.resume()
    }
    
    func updateErrorChart() {
        
        self.exceptionChart.noDataText = "Data not available"

        var exceptionDataEntries: [ChartDataEntry] = []
        var crashDataEntries: [ChartDataEntry] = []
        var dates: [String] = []
        
        var dataSets: [LineChartDataSet] = []
        
        // if we have exception data, add it to the set
        if(self.exceptionData.count > 0) {
            for i in 00..<self.exceptionData.count {
                
                let bucketData:NSDictionary = self.exceptionData[i] as AnyObject! as! NSDictionary
                let value:Int = bucketData["value"] as AnyObject! as! Int
                let dateString:String = bucketData["date"] as AnyObject! as! String
                
                // convert the start string into an nsdate
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'"
                let date:NSDate = dateFormatter.dateFromString(dateString)!
                
                dateFormatter.dateFormat = "MM/dd"
                let newDateString = dateFormatter.stringFromDate(date)
                
                let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
                
                if !dates.contains(newDateString) {
                    dates.append(newDateString)
                }
                
                exceptionDataEntries.append(dataEntry)
            }
            
            let exceptionSet = LineChartDataSet(yVals: exceptionDataEntries, label: "Exceptions")
            exceptionSet.setColor(UIColor.orangeColor())
            exceptionSet.setCircleColor(UIColor.orangeColor())
            exceptionSet.drawCircleHoleEnabled = false
            exceptionSet.fillColor = UIColor.redColor()
            exceptionSet.lineWidth = 5.0
            exceptionSet.circleRadius = 0
            exceptionSet.drawValuesEnabled = false

            dataSets.append(exceptionSet)
        }
        
        // if we have crash data, add it to the set
        if(self.crashData.count > 0) {
            for i in 00..<self.crashData.count {
                
                let bucketData:NSDictionary = self.crashData[i] as AnyObject! as! NSDictionary
                let value:Int = bucketData["value"] as AnyObject! as! Int
                let dateString:String = bucketData["date"] as AnyObject! as! String
                
                // convert the start string into an nsdate
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'"
                let date:NSDate = dateFormatter.dateFromString(dateString)!
                
                dateFormatter.dateFormat = "MM/dd"
                let newDateString = dateFormatter.stringFromDate(date)
                
                let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
                
                if !dates.contains(newDateString) {
                    dates.append(newDateString)
                }

                crashDataEntries.append(dataEntry)
            }

            
            let crashSet = LineChartDataSet(yVals: crashDataEntries, label: "Crashes")
            crashSet.setColor(UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255))
            crashSet.setCircleColor(UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255))
            crashSet.drawCircleHoleEnabled = false
            crashSet.fillColor = UIColor.redColor()
            crashSet.lineWidth = 5.0
            crashSet.circleRadius = 0
            crashSet.drawValuesEnabled = false

            dataSets.append(crashSet)
        }
        
        
        let chartData = LineChartData(xVals: dates, dataSets: dataSets)
        self.exceptionChart.data = chartData
    }
    
    func drawDAUChart(jsonDict: NSDictionary) {
        dauChart.noDataText = "Data not available"
        
        let series:NSDictionary = jsonDict["series"] as AnyObject! as! NSDictionary
        let buckets:NSArray = series["buckets"] as AnyObject! as! NSArray
        
        var dataEntries: [ChartDataEntry] = []
        var dates: [String] = []
        
        for i in 0..<buckets.count {
            let bucketData:NSDictionary = buckets[i] as AnyObject! as! NSDictionary
            let value:Int = bucketData["value"] as AnyObject! as! Int
            let dateString:String = bucketData["start"] as AnyObject! as! String
            
            // convert the start string into an nsdate
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
            let date:NSDate = dateFormatter.dateFromString(dateString)!
            
            dateFormatter.dateFormat = "MM/dd"
            let newDateString = dateFormatter.stringFromDate(date)
            
            let dataEntry = ChartDataEntry(value: Double(value), xIndex: i)
            
            dates.append(newDateString)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: "Active Users")
        
        chartDataSet.setColor(UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255))
        chartDataSet.setCircleColor(UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255))
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.fillColor = UIColor.redColor()
        chartDataSet.lineWidth = 5.0
        chartDataSet.circleRadius = 0
        chartDataSet.drawValuesEnabled = false
        
        let chartData = LineChartData(xVals: dates, dataSet: chartDataSet)
        
        dauChart.data = chartData
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
        
        print(processedData)
        print(sortedKeys)

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

        
        let chartDataSet = PieChartDataSet(yVals: dataEntries, label: "Carriers")
        chartDataSet.sliceSpace = 2.0
        chartDataSet.drawValuesEnabled = false
        chartDataSet.colors = [
            UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255),
            UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255),
            UIColor(red: 198/255, green: 96/255, blue: 187/255, alpha: 255/255),
            UIColor(red: 66/255, green: 199/255, blue: 111/255, alpha: 255/255),
            UIColor(red: 67/255, green: 163/255, blue: 237/255, alpha: 255/255),
            UIColor.orangeColor(),
        ]
        
        let chartData = PieChartData(xVals: carriers, dataSet: chartDataSet)
        
        self.carrierChart.data = chartData
    }
    
    func updateTime() {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        timeLabel.text = dateFormatter.stringFromDate(NSDate())
    }
}

