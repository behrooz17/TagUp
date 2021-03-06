//
//  ChartLegend.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 24/2/15.

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


open class ChartLegend: ChartComponentBase
{
    @objc
    public enum ChartLegendPosition: Int
    {
        case rightOfChart
        case rightOfChartCenter
        case rightOfChartInside
        case leftOfChart
        case leftOfChartCenter
        case leftOfChartInside
        case belowChartLeft
        case belowChartRight
        case belowChartCenter
        case aboveChartLeft
        case aboveChartRight
        case aboveChartCenter
        case piechartCenter
    }
    
    @objc
    public enum ChartLegendForm: Int
    {
        case square
        case circle
        case line
    }
    
    @objc
    public enum ChartLegendDirection: Int
    {
        case leftToRight
        case rightToLeft
    }

    /// the legend colors array, each color is for the form drawn at the same index
    open var colors = [NSUIColor?]()
    
    // the legend text array. a nil label will start a group.
    open var labels = [String?]()
    
    internal var _extraColors = [NSUIColor?]()
    internal var _extraLabels = [String?]()
    
    /// colors that will be appended to the end of the colors array after calculating the legend.
    open var extraColors: [NSUIColor?] { return _extraColors; }
    
    /// labels that will be appended to the end of the labels array after calculating the legend. a nil label will start a group.
    open var extraLabels: [String?] { return _extraLabels; }
    
    /// Are the legend labels/colors a custom value or auto calculated? If false, then it's auto, if true, then custom.
    /// 
    /// **default**: false (automatic legend)
    fileprivate var _isLegendCustom = false

    open var position = ChartLegendPosition.belowChartLeft
    open var direction = ChartLegendDirection.leftToRight

    open var font: NSUIFont = NSUIFont.systemFont(ofSize: 10.0)
    open var textColor = NSUIColor.black

    open var form = ChartLegendForm.square
    open var formSize = CGFloat(8.0)
    open var formLineWidth = CGFloat(1.5)
    
    open var xEntrySpace = CGFloat(6.0)
    open var yEntrySpace = CGFloat(0.0)
    open var formToTextSpace = CGFloat(5.0)
    open var stackSpace = CGFloat(3.0)
    
    open var calculatedLabelSizes = [CGSize]()
    open var calculatedLabelBreakPoints = [Bool]()
    open var calculatedLineSizes = [CGSize]()
    
    public override init()
    {
        super.init()
        
        self.xOffset = 5.0
        self.yOffset = 4.0
    }
    
    public init(colors: [NSUIColor?], labels: [String?])
    {
        super.init()
        
        self.colors = colors
        self.labels = labels
    }
    
    public init(colors: [NSObject], labels: [NSObject])
    {
        super.init()
        
        self.colorsObjc = colors
        self.labelsObjc = labels
    }
    
    open func getMaximumEntrySize(_ font: NSUIFont) -> CGSize
    {
        var maxW = CGFloat(0.0)
        var maxH = CGFloat(0.0)
        
        var labels = self.labels
        for i in 0 ..< labels.count
        {
            if (labels[i] == nil)
            {
                continue
            }
            
            let size = (labels[i] as NSString!).size(attributes: [NSFontAttributeName: font])
            
            if (size.width > maxW)
            {
                maxW = size.width
            }
            if (size.height > maxH)
            {
                maxH = size.height
            }
        }
        
        return CGSize(
            width: maxW + formSize + formToTextSpace,
            height: maxH
        )
    }
    
    open func getLabel(_ index: Int) -> String?
    {
        return labels[index]
    }
    
    open func getFullSize(_ labelFont: NSUIFont) -> CGSize
    {
        var width = CGFloat(0.0)
        var height = CGFloat(0.0)
        
        var labels = self.labels
        let count = labels.count
        for i in 0 ..< count
        {
            if (labels[i] != nil)
            {
                // make a step to the left
                if (colors[i] != nil)
                {
                    width += formSize + formToTextSpace
                }
                
                let size = (labels[i] as NSString!).size(attributes: [NSFontAttributeName: labelFont])
                
                width += size.width
                height += size.height
                
                if (i < count - 1)
                {
                    width += xEntrySpace
                    height += yEntrySpace
                }
            }
            else
            {
                width += formSize + stackSpace
                
                if (i < count - 1)
                {
                    width += stackSpace
                }
            }
        }
        
        return CGSize(width: width, height: height)
    }

    open var neededWidth = CGFloat(0.0)
    open var neededHeight = CGFloat(0.0)
    open var textWidthMax = CGFloat(0.0)
    open var textHeightMax = CGFloat(0.0)
    
    /// flag that indicates if word wrapping is enabled
    /// this is currently supported only for: `BelowChartLeft`, `BelowChartRight`, `BelowChartCenter`.
    /// note that word wrapping a legend takes a toll on performance.
    /// you may want to set maxSizePercent when word wrapping, to set the point where the text wraps.
    /// 
    /// **default**: false
    open var wordWrapEnabled = false
    
    /// if this is set, then word wrapping the legend is enabled.
    open var isWordWrapEnabled: Bool { return wordWrapEnabled }

    /// The maximum relative size out of the whole chart view in percent.
    /// If the legend is to the right/left of the chart, then this affects the width of the legend.
    /// If the legend is to the top/bottom of the chart, then this affects the height of the legend.
    /// If the legend is the center of the piechart, then this defines the size of the rectangular bounds out of the size of the "hole".
    /// 
    /// **default**: 0.95 (95%)
    open var maxSizePercent: CGFloat = 0.95
    
    open func calculateDimensions(labelFont: NSUIFont, viewPortHandler: ChartViewPortHandler)
    {
        if (position == .rightOfChart
            || position == .rightOfChartCenter
            || position == .leftOfChart
            || position == .leftOfChartCenter
            || position == .piechartCenter)
        {
            let maxEntrySize = getMaximumEntrySize(labelFont)
            let fullSize = getFullSize(labelFont)
            
            neededWidth = maxEntrySize.width
            neededHeight = fullSize.height
            textWidthMax = maxEntrySize.width
            textHeightMax = maxEntrySize.height
        }
        else if (position == .belowChartLeft
            || position == .belowChartRight
            || position == .belowChartCenter
            || position == .aboveChartLeft
            || position == .aboveChartRight
            || position == .aboveChartCenter)
        {
            var labels = self.labels
            var colors = self.colors
            let labelCount = labels.count
            
            let labelLineHeight = labelFont.lineHeight
            let formSize = self.formSize
            let formToTextSpace = self.formToTextSpace
            let xEntrySpace = self.xEntrySpace
            let stackSpace = self.stackSpace
            let wordWrapEnabled = self.wordWrapEnabled
            
            let contentWidth: CGFloat = viewPortHandler.contentWidth
            
            // Prepare arrays for calculated layout
            if (calculatedLabelSizes.count != labelCount)
            {
                calculatedLabelSizes = [CGSize](repeating: CGSize(), count: labelCount)
            }
            
            if (calculatedLabelBreakPoints.count != labelCount)
            {
                calculatedLabelBreakPoints = [Bool](repeating: false, count: labelCount)
            }
            
            calculatedLineSizes.removeAll(keepingCapacity: true)
            
            // Start calculating layout
            
            let labelAttrs = [NSFontAttributeName: labelFont]
            var maxLineWidth: CGFloat = 0.0
            var currentLineWidth: CGFloat = 0.0
            var requiredWidth: CGFloat = 0.0
            var stackedStartIndex: Int = -1
            
            for i in 0 ..< labelCount
            {
                let drawingForm = colors[i] != nil
                
                calculatedLabelBreakPoints[i] = false
                
                if (stackedStartIndex == -1)
                {
                    // we are not stacking, so required width is for this label only
                    requiredWidth = 0.0
                }
                else
                {
                    // add the spacing appropriate for stacked labels/forms
                    requiredWidth += stackSpace
                }
                
                // grouped forms have null labels
                if (labels[i] != nil)
                {
                    calculatedLabelSizes[i] = (labels[i] as NSString!).size(attributes: labelAttrs)
                    requiredWidth += drawingForm ? formToTextSpace + formSize : 0.0
                    requiredWidth += calculatedLabelSizes[i].width
                }
                else
                {
                    calculatedLabelSizes[i] = CGSize()
                    requiredWidth += drawingForm ? formSize : 0.0
                    
                    if (stackedStartIndex == -1)
                    {
                        // mark this index as we might want to break here later
                        stackedStartIndex = i
                    }
                }
                
                if (labels[i] != nil || i == labelCount - 1)
                {
                    let requiredSpacing = currentLineWidth == 0.0 ? 0.0 : xEntrySpace
                    
                    if (!wordWrapEnabled || // No word wrapping, it must fit.
                        currentLineWidth == 0.0 || // The line is empty, it must fit.
                        (contentWidth - currentLineWidth >= requiredSpacing + requiredWidth)) // It simply fits
                    {
                        // Expand current line
                        currentLineWidth += requiredSpacing + requiredWidth
                    }
                    else
                    { // It doesn't fit, we need to wrap a line
                        
                        // Add current line size to array
                        calculatedLineSizes.append(CGSize(width: currentLineWidth, height: labelLineHeight))
                        maxLineWidth = max(maxLineWidth, currentLineWidth)
                        
                        // Start a new line
                        calculatedLabelBreakPoints[stackedStartIndex > -1 ? stackedStartIndex : i] = true
                        currentLineWidth = requiredWidth
                    }
                    
                    if (i == labelCount - 1)
                    { // Add last line size to array
                        calculatedLineSizes.append(CGSize(width: currentLineWidth, height: labelLineHeight))
                        maxLineWidth = max(maxLineWidth, currentLineWidth)
                    }
                }
                
                stackedStartIndex = labels[i] != nil ? -1 : stackedStartIndex
            }
            
            let maxEntrySize = getMaximumEntrySize(labelFont)
            
            textWidthMax = maxEntrySize.width
            textHeightMax = maxEntrySize.height
            neededWidth = maxLineWidth
            neededHeight = labelLineHeight * CGFloat(calculatedLineSizes.count) +
                yEntrySpace * CGFloat(calculatedLineSizes.count == 0 ? 0 : (calculatedLineSizes.count - 1))
        }
        else
        {
            let maxEntrySize = getMaximumEntrySize(labelFont)
            let fullSize = getFullSize(labelFont)
            
            /* RightOfChartInside, LeftOfChartInside */
            neededWidth = fullSize.width
            neededHeight = maxEntrySize.height
            textWidthMax = maxEntrySize.width
            textHeightMax = maxEntrySize.height
        }
    }
    
    /// MARK: - Custom legend
    
    /// colors and labels that will be appended to the end of the auto calculated colors and labels after calculating the legend.
    /// (if the legend has already been calculated, you will need to call notifyDataSetChanged() to let the changes take effect)
    open func setExtra(colors: [NSUIColor?], labels: [String?])
    {
        self._extraLabels = labels
        self._extraColors = colors
    }
    
    /// Sets a custom legend's labels and colors arrays.
    /// The colors count should match the labels count.
    /// * Each color is for the form drawn at the same index.
    /// * A nil label will start a group.
    /// * A nil color will avoid drawing a form, and a clearColor will leave a space for the form.
    /// This will disable the feature that automatically calculates the legend labels and colors from the datasets.
    /// Call `resetCustom(...)` to re-enable automatic calculation (and then `notifyDataSetChanged()` is needed).
    open func setCustom(colors: [NSUIColor?], labels: [String?])
    {
        self.labels = labels
        self.colors = colors
        _isLegendCustom = true
    }
    
    /// Calling this will disable the custom legend labels (set by `setLegend(...)`). Instead, the labels will again be calculated automatically (after `notifyDataSetChanged()` is called).
    open func resetCustom()
    {
        _isLegendCustom = false
    }
    
    /// **default**: false (automatic legend)
    /// - returns: true if a custom legend labels and colors has been set
    open var isLegendCustom: Bool
    {
        return _isLegendCustom
    }
    
    /// MARK: - ObjC compatibility
    
    /// colors that will be appended to the end of the colors array after calculating the legend.
    open var extraColorsObjc: [NSObject] { return ChartUtils.bridgedObjCGetNSUIColorArray(swift: _extraColors); }
    
    /// labels that will be appended to the end of the labels array after calculating the legend. a nil label will start a group.
    open var extraLabelsObjc: [NSObject] { return ChartUtils.bridgedObjCGetStringArray(swift: _extraLabels); }
    
    /// the legend colors array, each color is for the form drawn at the same index
    /// (ObjC bridging functions, as Swift 1.2 does not bridge optionals in array to `NSNull`s)
    open var colorsObjc: [NSObject]
    {
        get { return ChartUtils.bridgedObjCGetNSUIColorArray(swift: colors); }
        set { self.colors = ChartUtils.bridgedObjCGetNSUIColorArray(objc: newValue); }
    }
    
    // the legend text array. a nil label will start a group.
    /// (ObjC bridging functions, as Swift 1.2 does not bridge optionals in array to `NSNull`s)
    open var labelsObjc: [NSObject]
    {
        get { return ChartUtils.bridgedObjCGetStringArray(swift: labels); }
        set { self.labels = ChartUtils.bridgedObjCGetStringArray(objc: newValue); }
    }
    
    /// colors and labels that will be appended to the end of the auto calculated colors and labels after calculating the legend.
    /// (if the legend has already been calculated, you will need to call `notifyDataSetChanged()` to let the changes take effect)
    open func setExtra(colors: [NSObject], labels: [NSObject])
    {
        if (colors.count != labels.count)
        {
            fatalError("ChartLegend:setExtra() - colors array and labels array need to be of same size")
        }
        
        self._extraLabels = ChartUtils.bridgedObjCGetStringArray(objc: labels)
        self._extraColors = ChartUtils.bridgedObjCGetNSUIColorArray(objc: colors)
    }
    
    /// Sets a custom legend's labels and colors arrays.
    /// The colors count should match the labels count.
    /// * Each color is for the form drawn at the same index.
    /// * A nil label will start a group.
    /// * A nil color will avoid drawing a form, and a clearColor will leave a space for the form.
    /// This will disable the feature that automatically calculates the legend labels and colors from the datasets.
    /// Call `resetLegendToAuto(...)` to re-enable automatic calculation, and then if needed - call `notifyDataSetChanged()` on the chart to make it refresh the data.
    open func setCustom(colors: [NSObject], labels: [NSObject])
    {
        if (colors.count != labels.count)
        {
            fatalError("ChartLegend:setCustom() - colors array and labels array need to be of same size")
        }
        
        self.labelsObjc = labels
        self.colorsObjc = colors
        _isLegendCustom = true
    }
}
