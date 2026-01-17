//
//  ContributionGraphView.swift
//  gitisland
//
//  GitHub contribution graph visualization
//

import SwiftUI

// Animation state for a single box in the loading animation
struct BoxAnimationState: Identifiable {
    let id: UUID
    let weekIndex: Int
    let dayIndex: Int
    var intensity: Double // 0.0 to 1.0, decreases over time for gradient trail
    var timestamp: Date
}

struct ContributionGraphView: View {
    let data: ContributionData
    @Binding var hoveredDay: ContributionDay?
    @Binding var tooltipPosition: CGPoint

    // Loading animation state
    @State private var isAnimating: Bool = true
    @State private var animatedBoxes: [BoxAnimationState] = []
    @State private var animationTimer: Timer?
    @State private var animationStartTime: Date = Date()

    private let squareSize: CGFloat = 11
    private let squareSpacing: CGFloat = 3.5
    private let animationDuration: TimeInterval = 3.0 // 3 seconds
    private let boxAnimationInterval: TimeInterval = 0.03 // Add new animated box every 30ms

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contribution grid
            HStack(alignment: .top, spacing: squareSpacing) {
                ForEach(data.weeks.indices, id: \.self) { weekIndex in
                    VStack(spacing: squareSpacing) {
                        ForEach(data.weeks[weekIndex].days.indices, id: \.self) { dayIndex in
                            contributionSquare(
                                for: data.weeks[weekIndex].days[dayIndex],
                                weekIndex: weekIndex,
                                dayIndex: dayIndex
                            )
                        }
                    }
                }
            }

            // Month labels
            monthLabels
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            checkAndStartLoadingAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    @ViewBuilder
    private var monthLabels: some View {
        ZStack(alignment: .leading) {
            ForEach(getMonthLabelPositions(), id: \.weekIndex) { position in
                Text(position.monthName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .offset(x: CGFloat(position.weekIndex) * (squareSize + squareSpacing))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 16)
    }

    private struct MonthLabelPosition {
        let weekIndex: Int
        let monthName: String
    }

    private func getMonthLabelPositions() -> [MonthLabelPosition] {
        var positions: [MonthLabelPosition] = []
        var labeledMonths: Set<Int> = []

        for weekIndex in data.weeks.indices {
            let week = data.weeks[weekIndex]

            // A full week should have 7 days
            guard week.days.count == 7 else { continue }

            // Check if all days in this week belong to the same month
            let months = Set(week.days.map { Calendar.current.component(.month, from: $0.date) })

            // If this is a full week for a single month
            if months.count == 1, let month = months.first {
                // Skip August (month 8) to prevent overflow
                guard month != 8 else { continue }

                // Only add label if we haven't labeled this month yet
                if !labeledMonths.contains(month) {
                    labeledMonths.insert(month)
                    // Shift by one column to the right
                    let shiftedWeekIndex = weekIndex + 1
                    // Make sure we don't go out of bounds
                    if shiftedWeekIndex < data.weeks.count {
                        positions.append(MonthLabelPosition(
                            weekIndex: shiftedWeekIndex,
                            monthName: monthName(from: week.days[0].date)
                        ))
                    }
                }
            }
        }

        return positions
    }

    private func monthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func contributionSquare(for day: ContributionDay, weekIndex: Int, dayIndex: Int) -> some View {
        GeometryReader { geometry in
            let animationState = animatedBoxes.first(where: { $0.weekIndex == weekIndex && $0.dayIndex == dayIndex })
            let fillColor = isAnimating ? animatedColor(for: animationState) : Color(hex: day.color)

            RoundedRectangle(cornerRadius: 2.5)
                .fill(fillColor)
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

    // MARK: - Loading Animation

    private func checkAndStartLoadingAnimation() {
        // Check if this is the first load
        let hasSeenAnimation = UserDefaults.standard.bool(forKey: "hasSeenContributionLoadingAnimation")

        if !hasSeenAnimation {
            // Mark as seen for future loads
            UserDefaults.standard.set(true, forKey: "hasSeenContributionLoadingAnimation")
            startLoadingAnimation()
        } else {
            // Skip animation, show data immediately
            isAnimating = false
        }
    }

    private func startLoadingAnimation() {
        isAnimating = true
        animationStartTime = Date()

        // Create a timer that fires frequently to add new animated boxes
        animationTimer = Timer.scheduledTimer(withTimeInterval: boxAnimationInterval, repeats: true) { _ in
            updateLoadingAnimation()
        }
    }

    private func updateLoadingAnimation() {
        let elapsed = Date().timeIntervalSince(animationStartTime)

        // Stop animation after duration
        if elapsed >= animationDuration {
            stopAnimation()
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = false
            }
            return
        }

        // Add new random box to animate
        if let randomWeekIndex = data.weeks.indices.randomElement(),
           let randomDayIndex = data.weeks[randomWeekIndex].days.indices.randomElement() {

            // Check if this box is already animating
            let alreadyAnimating = animatedBoxes.contains(where: {
                $0.weekIndex == randomWeekIndex && $0.dayIndex == randomDayIndex
            })

            if !alreadyAnimating {
                let newBox = BoxAnimationState(
                    id: UUID(),
                    weekIndex: randomWeekIndex,
                    dayIndex: randomDayIndex,
                    intensity: 1.0,
                    timestamp: Date()
                )
                animatedBoxes.append(newBox)
            }
        }

        // Update existing animated boxes - fade them out over time
        let now = Date()
        animatedBoxes = animatedBoxes.compactMap { box in
            let timeSinceStart = now.timeIntervalSince(box.timestamp)
            let fadeOutDuration = 0.8 // Fade out over 800ms for gradient trail
            let newIntensity = max(0, 1.0 - (timeSinceStart / fadeOutDuration))

            // Remove if fully faded
            if newIntensity <= 0 {
                return nil
            }

            // Update intensity
            var updatedBox = box
            updatedBox.intensity = newIntensity
            return updatedBox
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animatedBoxes.removeAll()
    }

    private func animatedColor(for state: BoxAnimationState?) -> Color {
        guard let state = state else {
            // Default empty state color during animation
            return Color(hex: "#161b22")
        }

        // Create elegant gradient trail effect using white/grey shades
        // Start with bright white, fade through light grey to dark grey
        let intensity = state.intensity

        if intensity > 0.7 {
            // Bright white phase - very bright
            let t = (intensity - 0.7) / 0.3 // 0 to 1
            let brightness = 0.85 + (0.15 * t) // 0.85 to 1.0
            return Color(white: brightness)
        } else if intensity > 0.4 {
            // Light grey phase
            let t = (intensity - 0.4) / 0.3 // 0 to 1
            let brightness = 0.5 + (0.35 * t) // 0.5 to 0.85
            return Color(white: brightness)
        } else if intensity > 0.15 {
            // Medium grey phase
            let t = (intensity - 0.15) / 0.25 // 0 to 1
            let brightness = 0.25 + (0.25 * t) // 0.25 to 0.5
            return Color(white: brightness)
        } else {
            // Fade to dark grey/empty state
            let t = intensity / 0.15 // 0 to 1
            let brightness = 0.09 + (0.16 * t) // 0.09 to 0.25
            return Color(white: brightness)
        }
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
