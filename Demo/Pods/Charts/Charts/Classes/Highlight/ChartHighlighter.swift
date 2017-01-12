//
//  ChartHighlighter.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 26/7/15.

//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics

open class ChartHighlighter : NSObject
{
    /// instance of the data-provider
    open weak var chart: BarLineChartViewBase?
    
    public init(chart: BarLineChartViewBase)
    {
        self.chart = chart
    }
    
    /// Returns a Highlight object corresponding to the given x- and y- touch positions in pixels.
    /// - parameter x:
    /// - parameter y:
    /// - returns:
    open func getHighlight(x: Double, y: Double) -> ChartHighlight?
    {
        let xIndex = getXIndex(x)
        if (xIndex == -Int.max)
        {
            return nil
        }
        
        let dataSetIndex = getDataSetIndex(xIndex: xIndex, x: x, y: y)
        if (dataSetIndex == -Int.max)
        {
            return nil
        }
        
        return ChartHighlight(xIndex: xIndex, dataSetIndex: dataSetIndex)
    }
    
    /// Returns the corresponding x-index for a given touch-position in pixels.
    /// - parameter x:
    /// - returns:
    open func getXIndex(_ x: Double) -> Int
    {
        // create an array of the touch-point
        var pt = CGPoint(x: x, y: 0.0)
        
        // take any transformer to determine the x-axis value
        self.chart?.getTransformer(ChartYAxis.AxisDependency.left).pixelToValue(&pt)
        
        return Int(round(pt.x))
    }
    
    /// Returns the corresponding dataset-index for a given xIndex and xy-touch position in pixels.
    /// - parameter xIndex:
    /// - parameter x:
    /// - parameter y:
    /// - returns:
    open func getDataSetIndex(xIndex: Int, x: Double, y: Double) -> Int
    {
        let valsAtIndex = getSelectionDetailsAtIndex(xIndex)
        
        let leftdist = ChartUtils.getMinimumDistance(valsAtIndex, val: y, axis: ChartYAxis.AxisDependency.left)
        let rightdist = ChartUtils.getMinimumDistance(valsAtIndex, val: y, axis: ChartYAxis.AxisDependency.right)
        
        let axis = leftdist < rightdist ? ChartYAxis.AxisDependency.left : ChartYAxis.AxisDependency.right
        
        let dataSetIndex = ChartUtils.closestDataSetIndex(valsAtIndex, value: y, axis: axis)
        
        return dataSetIndex
    }
    
    /// Returns a list of SelectionDetail object corresponding to the given xIndex.
    /// - parameter xIndex:
    /// - returns:
    open func getSelectionDetailsAtIndex(_ xIndex: Int) -> [ChartSelectionDetail]
    {
        var vals = [ChartSelectionDetail]()
        var pt = CGPoint()
        
        for i in 0 ..< (self.chart?.data?.dataSetCount ?? 0)
        {
            let dataSet = self.chart!.data!.getDataSetByIndex(i)
            
            // dont include datasets that cannot be highlighted
            if !dataSet.isHighlightEnabled
            {
                continue
            }
            
            // extract all y-values from all DataSets at the given x-index
            let yVal: Double = dataSet.yValForXIndex(xIndex)
            if yVal.isNaN
            {
                continue
            }
            
            pt.y = CGFloat(yVal)
            
            self.chart!.getTransformer(dataSet.axisDependency).pointValueToPixel(&pt)
            
            if !pt.y.isNaN
            {
                vals.append(ChartSelectionDetail(value: Double(pt.y), dataSetIndex: i, dataSet: dataSet))
            }
        }
        
        return vals
    }
}
