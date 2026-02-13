//
//  AnalyticsChartView.swift
//  trackmyrvu
//

import SwiftUI
import Charts

struct AnalyticsChartView: View {
    let summaries: [PeriodSummary]
    let selectedIndex: Int?
    var onBarTapped: ((Int) -> Void)?

    var body: some View {
        if summaries.isEmpty {
            emptyState
        } else {
            chartContent
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No data for selected range")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var chartContent: some View {
        let maxRVU = summaries.map(\.totalRVU).max() ?? 1

        return VStack(alignment: .leading, spacing: 4) {
            chartView(maxRVU: maxRVU)
                .frame(height: 220)
        }
        .padding(.vertical, 8)
    }

    private func chartView(maxRVU: Double) -> some View {
        let needsScroll = summaries.count > 7

        return Group {
            if needsScroll {
                ScrollView(.horizontal, showsIndicators: false) {
                    chart(maxRVU: maxRVU)
                        .frame(width: CGFloat(summaries.count) * 50)
                }
            } else {
                chart(maxRVU: maxRVU)
            }
        }
    }

    private func chart(maxRVU: Double) -> some View {
        Chart {
            ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                BarMark(
                    x: .value("Period", summary.periodLabel),
                    y: .value("RVU", summary.totalRVU)
                )
                .foregroundStyle(
                    selectedIndex == nil || selectedIndex == index
                        ? Color.blue.gradient
                        : Color.blue.opacity(0.3).gradient
                )

                LineMark(
                    x: .value("Period", summary.periodLabel),
                    y: .value("RVU", summary.totalRVU)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Period", summary.periodLabel),
                    y: .value("RVU", summary.totalRVU)
                )
                .foregroundStyle(.green)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 0...(maxRVU * 1.1))
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let plotFrame = proxy.plotFrame else { return }
                        let plotArea = geo[plotFrame]
                        let relativeX = location.x - plotArea.origin.x

                        if relativeX >= 0, relativeX <= plotArea.width, !summaries.isEmpty {
                            let barWidth = plotArea.width / CGFloat(summaries.count)
                            let index = Int(relativeX / barWidth)
                            let clampedIndex = min(max(index, 0), summaries.count - 1)
                            onBarTapped?(clampedIndex)
                        }
                    }
            }
        }
    }
}
