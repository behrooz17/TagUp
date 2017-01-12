//
//  PieChartDataSet.swift
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

open class PieChartDataSet: ChartDataSet, IPieChartDataSet
{
    fileprivate func initialize()
    {
        self.valueTextColor = NSUIColor.white
        self.valueFont = NSUIFont.systemFont(ofSize: 13.0)
    }
    
    public required init()
    {
        super.init()
        initialize()
    }
    
    public override init(yVals: [ChartDataEntry]?, label: String?)
    {
        super.init(yVals: yVals, label: label)
        initialize()
    }
    
    // MARK: - Styling functions and accessors
    
    fileprivate var _sliceSpace = CGFloat(0.0)
    
    /// the space in pixels between the pie-slices
    /// **default**: 0
    /// **maximum**: 20
    open var sliceSpace: CGFloat
    {
        get
        {
            return _sliceSpace
        }
        set
        {
            var space = newValue
            if (space > 20.0)
            {
                space = 20.0
            }
            if (space < 0.0)
            {
                space = 0.0
            }
            _sliceSpace = space
        }
    }
    
    /// indicates the selection distance of a pie slice
    open var selectionShift = CGFloat(18.0)
    
    // MARK: - NSCopying
    
    open override func copyWithZone(_ zone: NSZone?) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! PieChartDataSet
        copy._sliceSpace = _sliceSpace
        copy.selectionShift = selectionShift
        return copy
    }
}
