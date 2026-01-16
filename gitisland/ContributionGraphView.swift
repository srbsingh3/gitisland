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

    private let squareSize: CGFloat = 10
    private let squareSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Contribution grid
            HStack(alignment: .top, spacing: squareSpacing) {
                ForEach(Array(data.weeks.enumerated()), id: \.offset) { weekIndex, week in
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
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func contributionSquare(for day: ContributionDay) -> some View {
        Rectangle()
            .fill(Color(hex: day.color))
            .frame(width: squareSize, height: squareSize)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.1), lineWidth: hoveredDay?.id == day.id ? 1 : 0)
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoveredDay = day
                    tooltipPosition = CGPoint(
                        x: location.x + 15,
                        y: location.y - 10
                    )
                case .ended:
                    hoveredDay = nil
                }
            }
    }

    @ViewBuilder
    private func tooltipView(for day: ContributionDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(day.count) contribution\(day.count == 1 ? "" : "s")")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)

            Text(formatDate(day.date))
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoveredDay?.id)
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
