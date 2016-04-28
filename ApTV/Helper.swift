//
//  Helper.swift
//  ApTV
//
//  Created by Chris Beauchamp on 4/25/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit
import Charts

class Helper:NSObject {
    
    // called after the lineChart object is initialized, 
    // do some styling to make it look good!
    static func styleLineChart(chart:LineChartView) {

        // set the label displayed when no data exists
        chart.noDataText = "Data not available"
        
        // format the X-Axis
        chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        chart.xAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.xAxis.labelTextColor = UIColor.whiteColor()
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        
        // format the Y-Axis
        chart.leftAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.leftAxis.labelTextColor = UIColor.whiteColor()
        chart.leftAxis.drawAxisLineEnabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        
        // format the legend
        chart.legend.form = ChartLegend.ChartLegendForm.Line
        chart.legend.font = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.legend.textColor = UIColor.whiteColor()
        chart.legend.position = ChartLegend.ChartLegendPosition.BelowChartCenter
    }
    
    // called after the pieChart object is initialized,
    // do some styling to make it look good!
    static func stylePieChart(chart:PieChartView) {

        // set the label displayed when no data exists
        chart.noDataText = "Data not available"
        
        // turn off the legend
        chart.legend.enabled = false
        
        // make it donut-shaped and styled
        chart.holeRadiusPercent = 0.3
        chart.transparentCircleRadiusPercent = 0.35
        chart.holeColor = UIColor.blackColor()
        chart.transparentCircleColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    }
    
    // formats a specific line in the line charts (a single data set)
    static func formatDataSet(inout dataSet:LineChartDataSet, color:UIColor) {
        
        // set the color
        dataSet.setColor(color)
        dataSet.setCircleColor(color)
        
        // we don't want a circle, just a continuous line
        dataSet.drawCircleHoleEnabled = false
        dataSet.lineWidth = 5.0
        dataSet.circleRadius = 0
        
        // don't show the numeric values on each data point
        dataSet.drawValuesEnabled = false
    }
    
    // format the pie chart
    static func formatPieData(inout dataSet:PieChartDataSet) {
        
        // spread things out a bit
        dataSet.sliceSpace = 2.0
        
        // don't show the numeric values on each data slice
        dataSet.drawValuesEnabled = false
        
        // set the colors for the slices
        dataSet.colors = [
            UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255),
            UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255),
            UIColor(red: 198/255, green: 96/255, blue: 187/255, alpha: 255/255),
            UIColor(red: 66/255, green: 199/255, blue: 111/255, alpha: 255/255),
            UIColor(red: 67/255, green: 163/255, blue: 237/255, alpha: 255/255),
            UIColor.orangeColor(),
        ]
    }
    
    // parse the date string received from the API into something friendlier
    static func formatDateString(dateString:String, format:String) -> String {
        
        // create a date formatter that will parse the initial string
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        
        // get the NSDate object based on the initial string
        let date:NSDate = dateFormatter.dateFromString(dateString)!
        
        // override the dateFormatter with our desired output
        dateFormatter.dateFormat = "MM/dd"
        
        // return a pretty string from the initial date
        return dateFormatter.stringFromDate(date)
    }
    
    // take a data point from the API as input (bucket), and the
    // proper json keys, plus the input date format from the API =>
    // return a tuple with the data point value (y-value) and the 
    // formatted date string (x-value)
    static func parseBucket(bucket:AnyObject, valueKey:String, dateKey:String, dateFormat:String) -> (value:Int, dateString:String) {
        
        // convert the data to an NSDictionary
        let bucketData:NSDictionary = bucket as AnyObject! as! NSDictionary
        
        // get the y-value from the data set
        let value:Int = bucketData[valueKey] as AnyObject! as! Int
        
        // get the x-value (bucket date) from the JSON
        let dateString:String = bucketData[dateKey] as AnyObject! as! String
        
        // parse it and make it readable
        let formattedString:String = Helper.formatDateString(dateString, format: dateFormat)
        
        // return the tuple with both y and x values respectively
        return (value:value, dateString:formattedString)
    }

    // make the HTTP request to the API. The request is asynchronous and calls
    // the callback function on completion
    static func getData(url:String, method:String, params:AnyObject?, callback:(json:AnyObject) -> Void) {
        
        // get the access token from the settings. This is either
        // set by the user or the default from AppDelegate is used
        let accessToken:String = NSUserDefaults.standardUserDefaults().objectForKey("accessToken") as! String
        
        // set up the NSURLSession with the access token
        let sessionConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = ["Authorization": "Bearer " + accessToken]
        let session = NSURLSession(configuration:sessionConfig)

        // create the HTTP request
        let request = NSMutableURLRequest(URL:NSURL(string:url)!)
        request.HTTPMethod = method
        
        // if it's a POST method, set the proper HTTP headers
        if(method == "POST") {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        // if parameters should be passed into the API
        if(params != nil) {
            
            // set the HTTP body with the parameters JSON-ified
            do {
                try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params!, options:NSJSONWritingOptions.init(rawValue: 0))
            } catch { print("Invalid params", error) }
        }
        
        // make the asynchronous request
        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                // format the response data as JSON
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(), {
                    
                    // call back to the ViewController function. that callback
                    // should render the data
                    callback(json:json)
                })
                
            } catch {
                print("Error", error)
            }
        }.resume()
    }

}