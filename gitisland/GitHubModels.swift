//
//  GitHubModels.swift
//  gitisland
//
//  Data models for GitHub contribution data
//

import Foundation

struct ContributionDay: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let level: Int // 0-4 representing contribution intensity

    var color: String {
        switch level {
        case 0: return "#161b22"  // No contributions (dark gray)
        case 1: return "#0e4429"  // Low contributions
        case 2: return "#006d32"  // Medium-low contributions
        case 3: return "#26a641"  // Medium-high contributions
        case 4: return "#39d353"  // High contributions
        default: return "#161b22"
        }
    }
}

struct ContributionWeek {
    let days: [ContributionDay]
}

struct ContributionData {
    let weeks: [ContributionWeek]
    let totalContributions: Int
    let username: String
}
