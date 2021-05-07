//
//  LineAndBarProtocolsExtentions.swift
//  
//
//  Created by Will Dale on 13/02/2021.
//

import SwiftUI

// MARK: - Data Set
extension CTLineBarChartDataProtocol {
    public var range: Double {
        get {
            var _lowestValue: Double
            var _highestValue: Double
            
            switch self.chartStyle.baseline {
            case .minimumValue:
                _lowestValue = self.dataSets.minValue()
            case .minimumWithMaximum(of: let value):
                _lowestValue = min(self.dataSets.minValue(), value)
            case .zero:
                _lowestValue = 0
            }
            
            switch self.chartStyle.topLine {
            case .maximumValue:
                _highestValue = self.dataSets.maxValue()
            case .maximum(of: let value):
                _highestValue = max(self.dataSets.maxValue(), value)
            }
            
            return (_highestValue - _lowestValue) + 0.001
        }
    }
    
    public var minValue: Double {
        get {
            switch self.chartStyle.baseline {
            case .minimumValue:
                return self.dataSets.minValue()
            case .minimumWithMaximum(of: let value):
                return min(self.dataSets.minValue(), value)
            case .zero:
                return 0
            }
        }
    }
    
    public var maxValue: Double {
        get {
            switch self.chartStyle.topLine {
            case .maximumValue:
                return self.dataSets.maxValue()
            case .maximum(of: let value):
                return max(self.dataSets.maxValue(), value)
            }
        }
    }
    
    public var average: Double {
        return self.dataSets.average()
    }
}

// MARK: - Y Axis
extension CTLineBarChartDataProtocol {
    
    /**
     Array of labels generated but
     `getYLabels(_ specifier: String) -> [String]`.
     
     They are eight auto calculated numbers
     or array of strings.
     */
    private var labelsArray: [String] { self.getYLabels(self.viewData.yAxisSpecifier) }
    
    /**
     Labels to display on the Y axis
     
     If `yAxisLabelType`is set to `.numeric`, the labels get
     generated based on the range between the `minValue` and
     `maxValue`.
     
     If `yAxisLabelType`is set to `.custom`, the labels come
     from `ChartData -> yAxisLabels`.
     
     - Parameters:
        - specifier: Decimal precision of the labels.
     - Returns: Array of labels.
     */
    public func getYLabels(_ specifier: String) -> [String] {
        switch self.chartStyle.yAxisLabelType {
        case .numeric:
            let dataRange: Double = self.range
            let minValue: Double = self.minValue
            let range: Double = dataRange / Double(self.chartStyle.yAxisNumberOfLabels-1)
            let firstLabel = [String(format: self.viewData.yAxisSpecifier, minValue)]
            let otherLabels = (1...self.chartStyle.yAxisNumberOfLabels-1).map { String(format: self.viewData.yAxisSpecifier, minValue + range * Double($0)) }
            let labels = firstLabel + otherLabels
            return labels
        case .custom:
            return self.yAxisLabels ?? []
        }
    }
}

extension CTLineBarChartDataProtocol {
    public func showYAxisLabels() -> some View {
        VStack {
            ForEach(self.labelsArray.indices.reversed(), id: \.self) { i in
                Text(self.labelsArray[i])
                    .font(self.chartStyle.yAxisLabelFont)
                    .foregroundColor(self.chartStyle.yAxisLabelColour)
                    .lineLimit(1)
                    .overlay(
                        GeometryReader { geo in
                            Rectangle()
                                .foregroundColor(Color.clear)
                                .onAppear {
                                    self.viewData.yAxisLabelWidth.append(geo.size.width)
                                }
                        }
                    )
                    .accessibilityLabel(Text("Y Axis Label"))
                    .accessibilityValue(Text(self.labelsArray[i]))
                if i != 0 {
                    Spacer()
                        .frame(minHeight: 0, maxHeight: 500)
                }
            }
            Spacer()
                .frame(height: (self.viewData.xAxisLabelHeights.max() ?? 0) + self.viewData.xAxisTitleHeight + (self.viewData.hasXAxisLabels ? 4 : 0)) // 4 accounts for padding
        }
        .padding(.top, -8)
    }
}

// MARK: Axes Titles
extension CTLineBarChartDataProtocol {
    /**
     Returns the title for y axis.
     
     This also informs `ViewData` of it width so
     that the positioning of the views in the x axis
     can be calculated.
     */
    public func showYAxisTitle() -> some View {
        Group {
            if let title = self.chartStyle.yAxisTitle {
                VStack {
                    Text(title)
                        .font(self.chartStyle.yAxisTitleFont)
                        .background(
                            GeometryReader { geo in
                                Rectangle()
                                    .foregroundColor(Color.clear)
                                    .onAppear {
                                        self.viewData.yAxisTitleWidth = geo.size.height + 10 // 10 to add padding
                                    }
                            }
                        )
                        .rotationEffect(Angle.init(degrees: -90), anchor: .center)
                        .fixedSize()
                        .frame(width: self.viewData.yAxisTitleWidth)
                    Spacer()
                        .frame(height: (self.viewData.xAxisLabelHeights.max() ?? 0) + self.viewData.yAxisTitleWidth + (self.viewData.hasXAxisLabels ? 4 : 0)) // 4 accounts for padding
                }
            }
        }
    }
    /**
     Returns the title for x axis.
     
     This also informs `ViewData` of it height so
     that the positioning of the views in the y axis
     can be calculated.
     */
    internal func xAxisTitle() -> some View {
        Group {
            if let title = self.chartStyle.xAxisTitle {
                Text(title)
                    .font(self.chartStyle.xAxisTitleFont)
                    .background(
                        GeometryReader { geo in
                            Rectangle()
                                .foregroundColor(Color.clear)
                                .onAppear {
                                    self.viewData.xAxisTitleHeight = geo.size.height
                                }
                        }
                    )
            }
        }
    }
}

// MARK: - Y Axis POI
extension CTLineBarChartDataProtocol {
    public func poiMarker(value: Double, range: Double, minValue: Double) -> some Shape {
        HorizontalMarker(chartData: self, value: value, range: range, minValue: minValue)
    }
    public func poiLabelAxis(markerValue: Double, specifier: String, labelFont: Font, labelColour: Color, labelBackground: Color, lineColour: Color) -> some View {
        Text("\(markerValue, specifier: specifier)")
            .font(labelFont)
            .foregroundColor(labelColour)
            .padding(4)
            .background(labelBackground)
            .ifElse(self.chartStyle.yAxisLabelPosition == .leading, if: {
                $0
                    .clipShape(LeadingLabelShape())
                    .overlay(LeadingLabelShape()
                                .stroke(lineColour)
                    )
            }, else: {
                $0
                    .clipShape(TrailingLabelShape())
                    .overlay(TrailingLabelShape()
                                .stroke(lineColour)
                    )
            })
    }
}
extension CTLineBarChartDataProtocol where Self: isHorizontal {
    public func poiMarker(value: Double, range: Double, minValue: Double) -> some Shape {
        VerticalMarker(chartData: self, value: value, range: range, minValue: minValue)
    }
    public func poiLabelAxis(markerValue: Double, specifier: String, labelFont: Font, labelColour: Color, labelBackground: Color, lineColour: Color) -> some View {
        Text("\(markerValue, specifier: specifier)")
            .font(labelFont)
            .foregroundColor(labelColour)
            .padding(4)
            .background(labelBackground)
            .ifElse(self.chartStyle.xAxisLabelPosition == .bottom, if: {
                $0
                    .clipShape(BottomLabelShape())
                    .overlay(BottomLabelShape()
                                .stroke(lineColour)
                    )
            }, else: {
                $0
                    .clipShape(TopLabelShape())
                    .overlay(TopLabelShape()
                                .stroke(lineColour)
                    )
            })
    }
}

// MARK: Line Charts
extension CTLineBarChartDataProtocol where Self: CTLineChartDataProtocol {
    public func poiValueLabelPositionAxis(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        CGPoint(x: -((self.viewData.yAxisLabelWidth.max() ?? 0) / 2) - 4, // -4 for padding at the root.
                y: CGFloat(markerValue - minValue) * -(frame.height / CGFloat(range)) + frame.height)
    }
    public func poiValueLabelPositionCenter(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        CGPoint(x: frame.width / 2,
                y: CGFloat(markerValue - minValue) * -(frame.height / CGFloat(range)) + frame.height)
    }
}

// MARK: Vertical Bar Charts
extension CTLineBarChartDataProtocol where Self: CTBarChartDataProtocol {
    public func poiValueLabelPositionAxis(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        return CGPoint(x: -((self.viewData.yAxisLabelWidth.max() ?? 0) / 2) - 4, // -4 for padding at the root.
                y: frame.height - CGFloat((markerValue - minValue) / range) * frame.height)
    }
    public func poiValueLabelPositionCenter(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        CGPoint(x: frame.width / 2,
                y: frame.height - CGFloat((markerValue - minValue) / range) * frame.height)
    }
}

// MARK: Horizontal Bar Charts
extension CTLineBarChartDataProtocol where Self: CTBarChartDataProtocol,
                                           Self: isHorizontal {
    
    public func poiValueLabelPositionAxis(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        CGPoint(x: CGFloat((markerValue - minValue) / range) * frame.width,
                y: -((self.viewData.yAxisLabelWidth.max() ?? 0) / 2))
    }
    public func poiValueLabelPositionCenter(frame: CGRect, markerValue: Double, minValue: Double, range: Double) -> CGPoint {
        CGPoint(x: CGFloat((markerValue - minValue) / range) * frame.width,
                y: frame.height / 2)
    }
}
