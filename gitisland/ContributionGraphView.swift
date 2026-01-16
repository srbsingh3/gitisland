//
//  ContributionGraphView.swift
//  gitisland
//
//  GitHub contribution graph visualization
//

import SwiftUI

struct ContributionGraphView: View {
    let data: ContributionData
    @State private var hoveredDay: ContributionDay?
    @State private var tooltipPosition: CGPoint = .zero

    private let squareSize: CGFloat = 11
    private let squareSpacing: CGFloat = 3.5

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contribution grid
            HStack(alignment: .top, spacing: squareSpacing) {
                ForEach(Array(data.weeks.reversed().enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: squareSpacing) {
                        ForEach(Array(week.days.enumerated()), id: \.offset) { dayIndex, day in
                            contributionSquare(for: day)
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if let day = hoveredDay {
                    tooltipView(for: day)
                        .position(tooltipPosition)
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
            ForEach(Array(data.weeks.reversed().enumerated()), id: \.offset) { weekIndex, week in
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
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(hex: day.color))
            .frame(width: squareSize, height: squareSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: hoveredDay?.id == day.id ? 1.5 : 0)
            )
            .scaleEffect(hoveredDay?.id == day.id ? 1.1 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hoveredDay?.id == day.id)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoveredDay = day
                    tooltipPosition = CGPoint(
                        x: location.x + 18,
                        y: location.y - 8
                    )
                case .ended:
                    hoveredDay = nil
                }
            }
    }

    @ViewBuilder
    private func tooltipView(for day: ContributionDay) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(day.count) contribution\(day.count == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)

            Text(formatDate(day.date))
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(white: 0.12))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: hoveredDay?.id)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
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
