//
//  ContributionGraphView.swift
//  gitisland
//
//  GitHub contribution graph visualization
//

import SwiftUI

struct ContributionGraphView: View {
    let data: ContributionData
    @Binding var hoveredDay: ContributionDay?
    @Binding var tooltipPosition: CGPoint

    private let squareSize: CGFloat = 11
    private let squareSpacing: CGFloat = 3.5

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contribution grid
            HStack(alignment: .top, spacing: squareSpacing) {
                ForEach(data.weeks.indices, id: \.self) { weekIndex in
                    VStack(spacing: squareSpacing) {
                        ForEach(data.weeks[weekIndex].days.indices, id: \.self) { dayIndex in
                            contributionSquare(for: data.weeks[weekIndex].days[dayIndex])
                        }
                    }
                }
            }

            // Month labels
            monthLabels
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var monthLabels: some View {
        ZStack(alignment: .leading) {
            ForEach(data.weeks.indices, id: \.self) { weekIndex in
                let week = data.weeks[weekIndex]
                // Check if this week contains the 1st day of a month
                if let monthStart = week.days.first(where: { Calendar.current.component(.day, from: $0.date) == 1 }) {
                    let month = Calendar.current.component(.month, from: monthStart.date)

                    // Show Oct, Nov, Dec, Jan at their actual positions
                    let monthsToShow: Set<Int> = [1, 10, 11, 12] // Jan, Oct, Nov, Dec

                    if monthsToShow.contains(month) {
                        Text(monthName(from: monthStart.date))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: CGFloat(weekIndex) * (squareSize + squareSpacing))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 16)
    }

    private func monthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func contributionSquare(for day: ContributionDay) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(hex: day.color))
                .overlay(
                    RoundedRectangle(cornerRadius: 2.5)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: hoveredDay?.id == day.id ? 1.5 : 0)
                )
                .scaleEffect(hoveredDay?.id == day.id ? 1.1 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hoveredDay?.id == day.id)
                .onHover { isHovering in
                    if isHovering {
                        hoveredDay = day
                        // Get position in global coordinate space
                        let frame = geometry.frame(in: .global)
                        // Position tooltip above the box with margin
                        // Tooltip height is approximately 23 (padding 4*2 + text ~15)
                        // So position center at minY - 8 (margin) - 11.5 (half height) = minY - 19.5
                        tooltipPosition = CGPoint(x: frame.midX, y: frame.minY - 20)
                    } else if hoveredDay?.id == day.id {
                        hoveredDay = nil
                    }
                }
        }
        .frame(width: squareSize, height: squareSize)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// Tooltip view for contribution data
struct ContributionTooltipView: View {
    let day: ContributionDay

    var body: some View {
        HStack(spacing: 4) {
            Text("\(day.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)

            Text(formatDate(day.date))
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(white: 0.12))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .fixedSize()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// Helper extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
