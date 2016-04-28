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
    
    static func styleLineChart(chart:LineChartView) {
        chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        chart.xAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.xAxis.labelTextColor = UIColor.whiteColor()
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        
        chart.leftAxis.labelFont = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.leftAxis.labelTextColor = UIColor.whiteColor()
        chart.leftAxis.drawAxisLineEnabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        
        chart.legend.form = ChartLegend.ChartLegendForm.Line
        chart.legend.font = NSUIFont(name: "HelveticaNeue-Light", size: 14.0)!
        chart.legend.textColor = UIColor.whiteColor()
        chart.legend.position = ChartLegend.ChartLegendPosition.BelowChartCenter
    }
    
    static func stylePieChart(chart:PieChartView) {
        chart.noDataText = "Data not available"
        chart.legend.enabled = false
        
        chart.holeRadiusPercent = 0.3
        chart.transparentCircleRadiusPercent = 0.35
        chart.holeColor = UIColor.blackColor()
        chart.transparentCircleColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    }
    
    static func formatDataSet(inout dataSet:LineChartDataSet, color:UIColor) {
        dataSet.setColor(color)
        dataSet.setCircleColor(color)
        dataSet.drawCircleHoleEnabled = false
        dataSet.lineWidth = 5.0
        dataSet.circleRadius = 0
        dataSet.drawValuesEnabled = false
    }
    
    static func formatPieData(inout dataSet:PieChartDataSet) {
        dataSet.sliceSpace = 2.0
        dataSet.drawValuesEnabled = false
        dataSet.colors = [
            UIColor(red: 72/255, green: 186/255, blue: 175/255, alpha: 255/255),
            UIColor(red: 237/255, green: 72/255, blue: 67/255, alpha: 255/255),
            UIColor(red: 198/255, green: 96/255, blue: 187/255, alpha: 255/255),
            UIColor(red: 66/255, green: 199/255, blue: 111/255, alpha: 255/255),
            UIColor(red: 67/255, green: 163/255, blue: 237/255, alpha: 255/255),
            UIColor.orangeColor(),
        ]
    }
    
    static func parseBucket(bucket:AnyObject, valueKey:String, dateKey:String, dateFormat:String) -> (value:Int, dateString:String) {
        let bucketData:NSDictionary = bucket as AnyObject! as! NSDictionary
        let value:Int = bucketData[valueKey] as AnyObject! as! Int
        
        let dateString:String = bucketData[dateKey] as AnyObject! as! String
        let formattedString:String = Helper.formatDateString(dateString, format: dateFormat)

        return (value:value, dateString:formattedString)
    }
    
    static func formatDateString(dateString:String, format:String) -> String {
        // convert the start string into an nsdate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        let date:NSDate = dateFormatter.dateFromString(dateString)!
        dateFormatter.dateFormat = "MM/dd"
        return dateFormatter.stringFromDate(date)
    }
    
    static func getData(url:String, method:String, params:AnyObject?, callback:(json:AnyObject) -> Void) {
        
        // set our class variables on view appear so it's loaded on first load, or after settings have changed
        let accessToken:String = NSUserDefaults.standardUserDefaults().objectForKey("accessToken") as! String
        
        let sessionConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = ["Authorization": "Bearer " + accessToken]
        
        let session = NSURLSession(configuration:sessionConfig)

        let endpoint = NSURL(string:url)
        let request = NSMutableURLRequest(URL:endpoint!)
        request.HTTPMethod = method
        
        if(method == "POST") {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        if(params != nil) {
            do {
                try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params!, options:NSJSONWritingOptions.init(rawValue: 0))
            } catch { print("Invalid params", error) }
        }
        
        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                
                // we want to make sure this is run on the proper thread
                dispatch_async(dispatch_get_main_queue(),{
                    callback(json:json)
                })
                
            } catch {
                print("Error", error)
            }
        }.resume()
    }

}