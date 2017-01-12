//
//  ChartLegendRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


open class ChartLegendRenderer: ChartRendererBase
{
    /// the legend object this renderer renders
    open var legend: ChartLegend?

    public init(viewPortHandler: ChartViewPortHandler, legend: ChartLegend?)
    {
        super.init(viewPortHandler: viewPortHandler)
        
        self.legend = legend
    }

    /// Prepares the legend and calculates all needed forms, labels and colors.
    open func computeLegend(_ data: ChartData)
    {
        guard let legend = legend else { return }
        
        if (!legend.isLegendCustom)
        {
            var labels = [String?]()
            var colors = [NSUIColor?]()
            
            // loop for building up the colors and labels used in the legend
            for i in 0..<data.dataSetCount
            {
                let dataSet = data.getDataSetByIndex(i)!
                
                var clrs: [NSUIColor] = dataSet.colors
                let entryCount = dataSet.entryCount
                
                // if we have a barchart with stacked bars
                if (dataSet is IBarChartDataSet && (dataSet as! IBarChartDataSet).isStacked)
                {
                    let bds = dataSet as! IBarChartDataSet
                    var sLabels = bds.stackLabels
                    
                    for j in 0..<min(clrs.count, bds.stackSize)
                    {
                        labels.append(sLabels[j % sLabels.count])
                        colors.append(clrs[j])
                    }
                    
                    if (bds.label != nil)
                    {
                        // add the legend description label
                        colors.append(nil)
                        labels.append(bds.label)
                    }
                }
                else if (dataSet is IPieChartDataSet)
                {
                    var xVals = data.xVals
                    let pds = dataSet as! IPieChartDataSet
                    
                    for j in 0..<min(clrs.count, entryCount, xVals.count)
                    {
                        labels.append(xVals[j])
                        colors.append(clrs[j])
                    }
                    
                    if (pds.label != nil)
                    {
                        // add the legend description label
                        colors.append(nil)
                        labels.append(pds.label)
                    }
                }
                else if (dataSet is ICandleChartDataSet
                    && (dataSet as! ICandleChartDataSet).decreasingColor != nil)
                {
                    colors.append((dataSet as! ICandleChartDataSet).decreasingColor)
                    colors.append((dataSet as! ICandleChartDataSet).increasingColor)
                    labels.append(nil)
                    labels.append(dataSet.label)
                }
                else
                { // all others
                    
                    for j in 0..<min(clrs.count, entryCount)
                    {
                        // if multiple colors are set for a DataSet, group them
                        if (j < clrs.count - 1 && j < entryCount - 1)
                        {
                            labels.append(nil)
                        }
                        else
                        { // add label to the last entry
                            labels.append(dataSet.label)
                        }
                        
                        colors.append(clrs[j])
                    }
                }
            }
            
            legend.colors = colors + legend._extraColors
            legend.labels = labels + legend._extraLabels
        }
        
        // calculate all dimensions of the legend
        legend.calculateDimensions(labelFont: legend.font, viewPortHandler: viewPortHandler)
    }
    
    open func renderLegend(context: CGContext)
    {
        guard let legend = legend else { return }
        
        if !legend.enabled
        {
            return
        }
        
        let labelFont = legend.font
        let labelTextColor = legend.textColor
        let labelLineHeight = labelFont.lineHeight
        let formYOffset = labelLineHeight / 2.0

        var labels = legend.labels
        var colors = legend.colors
        
        let formSize = legend.formSize
        let formToTextSpace = legend.formToTextSpace
        let xEntrySpace = legend.xEntrySpace
        let direction = legend.direction

        // space between the entries
        let stackSpace = legend.stackSpace

        let yoffset = legend.yOffset
        let xoffset = legend.xOffset
        
        let legendPosition = legend.position
        
        switch (legendPosition)
        {
        case
        .belowChartLeft,
        .belowChartRight,
        .belowChartCenter,
        .aboveChartLeft,
        .aboveChartRight,
        .aboveChartCenter:
            
            let contentWidth: CGFloat = viewPortHandler.contentWidth
            
            var originPosX: CGFloat
            
            if (legendPosition == .belowChartLeft || legendPosition == .aboveChartLeft)
            {
                originPosX = viewPortHandler.contentLeft + xoffset
                
                if (direction == .rightToLeft)
                {
                    originPosX += legend.neededWidth
                }
            }
            else if (legendPosition == .belowChartRight || legendPosition == .aboveChartRight)
            {
                originPosX = viewPortHandler.contentRight - xoffset
                
                if (direction == .leftToRight)
                {
                    originPosX -= legend.neededWidth
                }
            }
            else // .BelowChartCenter || .AboveChartCenter
            {
                originPosX = viewPortHandler.contentLeft + contentWidth / 2.0
            }
            
            var calculatedLineSizes = legend.calculatedLineSizes
            var calculatedLabelSizes = legend.calculatedLabelSizes
            var calculatedLabelBreakPoints = legend.calculatedLabelBreakPoints
            
            var posX: CGFloat = originPosX
            var posY: CGFloat
            
            if (legendPosition == .aboveChartLeft
                || legendPosition == .aboveChartRight
                || legendPosition == .aboveChartCenter)
            {
                posY = 0
            }
            else
            {
                posY = viewPortHandler.chartHeight - yoffset - legend.neededHeight
            }
            
            var lineIndex: Int = 0
            
            
            for i in 0..<labels.count
            {
                if (i < calculatedLabelBreakPoints.count && calculatedLabelBreakPoints[i])
                {
                    posX = originPosX
                    posY += labelLineHeight
                }
                
                if (posX == originPosX &&
                    (legendPosition == .belowChartCenter ||
                    legendPosition == .aboveChartCenter) &&
                    lineIndex < calculatedLineSizes.count)
                {
                    posX += (direction == .rightToLeft ? calculatedLineSizes[lineIndex].width : -calculatedLineSizes[lineIndex].width) / 2.0
                    lineIndex += 1
                }
                
                let drawingForm = colors[i] != nil
                let isStacked = labels[i] == nil // grouped forms have null labels
                
                if (drawingForm)
                {
                    if (direction == .rightToLeft)
                    {
                        posX -= formSize
                    }
                    
                    drawForm(context: context, x: posX, y: posY + formYOffset, colorIndex: i, legend: legend)
                    
                    if (direction == .leftToRight)
                    {
                        posX += formSize
                    }
                }
                
                if (!isStacked)
                {
                    if (drawingForm)
                    {
                        posX += direction == .rightToLeft ? -formToTextSpace : formToTextSpace
                    }
                    
                    if (direction == .rightToLeft)
                    {
                        posX -= calculatedLabelSizes[i].width
                    }
                    
                    drawLabel(context: context, x: posX, y: posY, label: labels[i]!, font: labelFont, textColor: labelTextColor)
                    
                    if (direction == .leftToRight)
                    {
                        posX += calculatedLabelSizes[i].width
                    }
                    
                    posX += direction == .rightToLeft ? -xEntrySpace : xEntrySpace
                }
                else
                {
                    posX += direction == .rightToLeft ? -stackSpace : stackSpace
                }
            }
            
        case
        .piechartCenter,
        .rightOfChart,
        .rightOfChartCenter,
        .rightOfChartInside,
        .leftOfChart,
        .leftOfChartCenter,
        .leftOfChartInside:
            
            // contains the stacked legend size in pixels
            var stack = CGFloat(0.0)
            var wasStacked = false
            var posX: CGFloat = 0.0, posY: CGFloat = 0.0
            
            if (legendPosition == .piechartCenter)
            {
                posX = viewPortHandler.chartWidth / 2.0 + (direction == .leftToRight ? -legend.textWidthMax / 2.0 : legend.textWidthMax / 2.0)
                posY = viewPortHandler.chartHeight / 2.0 - legend.neededHeight / 2.0 + legend.yOffset
            }
            else
            {
                let isRightAligned = legendPosition == .rightOfChart ||
                    legendPosition == .rightOfChartCenter ||
                    legendPosition == .rightOfChartInside
                
                if (isRightAligned)
                {
                    posX = viewPortHandler.chartWidth - xoffset
                    if (direction == .leftToRight)
                    {
                        posX -= legend.textWidthMax
                    }
                }
                else
                {
                    posX = xoffset
                    if (direction == .rightToLeft)
                    {
                        posX += legend.textWidthMax
                    }
                }
                
                switch legendPosition
                {
                case .rightOfChart, .leftOfChart:
                    posY = viewPortHandler.contentTop + yoffset
                case .rightOfChartCenter, .leftOfChartCenter:
                    posY = viewPortHandler.chartHeight / 2.0 - legend.neededHeight / 2.0
                default: // case .RightOfChartInside, .LeftOfChartInside
                    posY = viewPortHandler.contentTop + yoffset
                }
            }
            
            for i in 0..<labels.count
            {
                let drawingForm = colors[i] != nil
                var x = posX
                
                if (drawingForm)
                {
                    if (direction == .leftToRight)
                    {
                        x += stack
                    }
                    else
                    {
                        x -= formSize - stack
                    }
                    
                    drawForm(context: context, x: x, y: posY + formYOffset, colorIndex: i, legend: legend)
                    
                    if (direction == .leftToRight)
                    {
                        x += formSize
                    }
                }
                
                if (labels[i] != nil)
                {
                    if (drawingForm && !wasStacked)
                    {
                        x += direction == .leftToRight ? formToTextSpace : -formToTextSpace
                    }
                    else if (wasStacked)
                    {
                        x = posX
                    }
                    
                    if (direction == .rightToLeft)
                    {
                        x -= (labels[i] as NSString!).size(attributes: [NSFontAttributeName: labelFont]).width
                    }
                    
                    if (!wasStacked)
                    {
                        drawLabel(context: context, x: x, y: posY, label: labels[i]!, font: labelFont, textColor: labelTextColor)
                    }
                    else
                    {
                        posY += labelLineHeight
                        drawLabel(context: context, x: x, y: posY, label: labels[i]!, font: labelFont, textColor: labelTextColor)
                    }
                    
                    // make a step down
                    posY += labelLineHeight
                    stack = 0.0
                }
                else
                {
                    stack += formSize + stackSpace
                    wasStacked = true
                }
            }
            
        }
    }

    fileprivate var _formLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    /// Draws the Legend-form at the given position with the color at the given index.
    open func drawForm(context: CGContext, x: CGFloat, y: CGFloat, colorIndex: Int, legend: ChartLegend)
    {
        guard let formColor = legend.colors[colorIndex], formColor != NSUIColor.clear else {
            return
        }
        
        let formsize = legend.formSize
        
        context.saveGState()
        defer { context.restoreGState() }
        
        switch (legend.form)
        {
        case .circle:
            context.setFillColor(formColor.cgColor)
            context.fillEllipse(in: CGRect(x: x, y: y - formsize / 2.0, width: formsize, height: formsize))
        case .square:
            context.setFillColor(formColor.cgColor)
            context.fill(CGRect(x: x, y: y - formsize / 2.0, width: formsize, height: formsize))
        case .line:
            
            context.setLineWidth(legend.formLineWidth)
            context.setStrokeColor(formColor.cgColor)
            
            _formLineSegmentsBuffer[0].x = x
            _formLineSegmentsBuffer[0].y = y
            _formLineSegmentsBuffer[1].x = x + formsize
            _formLineSegmentsBuffer[1].y = y
            CGContextStrokeLineSegments(context, _formLineSegmentsBuffer, 2)
        }
    }

    /// Draws the provided label at the given position.
    open func drawLabel(context: CGContext, x: CGFloat, y: CGFloat, label: String, font: NSUIFont, textColor: NSUIColor)
    {
        ChartUtils.drawText(context: context, text: label, point: CGPoint(x: x, y: y), align: .left, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
    }
}
