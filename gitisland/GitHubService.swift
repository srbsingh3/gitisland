//
//  GitHubService.swift
//  gitisland
//
//  Service for fetching GitHub contribution data
//

import Foundation
import Combine

enum GitHubError: Error {
    case invalidURL
    case noToken
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

@MainActor
class GitHubService: ObservableObject {
    @Published var contributionData: ContributionData?
    @Published var isLoading = false
    @Published var error: GitHubError?

    private let tokenKey = "GITHUB_TOKEN"

    func fetchContributions(username: String) async {
        isLoading = true
        error = nil

        // Generate mock data immediately
        contributionData = generateMockData(username: username)
        isLoading = false
    }

    private func generateMockData(username: String) -> ContributionData {
        let calendar = Calendar.current
        let today = Date()

        var weeks: [ContributionWeek] = []
        var totalContributions = 0

        // Generate 22 weeks of data (5 months)
        for weekOffset in (0..<22).reversed() {
            var days: [ContributionDay] = []

            for dayOffset in 0..<7 {
                let dayIndex = weekOffset * 7 + dayOffset
                guard let date = calendar.date(byAdding: .day, value: -dayIndex, to: today) else { continue }

                // Create varied contribution patterns
                let count: Int
                let level: Int

                // Add some randomness but with patterns
                let isWeekend = calendar.component(.weekday, from: date) == 1 || calendar.component(.weekday, from: date) == 7
                let weekNumber = weekOffset % 4

                if isWeekend {
                    // Lighter activity on weekends
                    count = Int.random(in: 0...3)
                } else {
                    // More activity during the week
                    switch weekNumber {
                    case 0: count = Int.random(in: 5...15) // High activity week
                    case 1: count = Int.random(in: 2...8)  // Medium activity week
                    case 2: count = Int.random(in: 0...4)  // Low activity week
                    case 3: count = Int.random(in: 1...6)  // Medium-low activity week
                    default: count = 0
                    }
                }

                // Determine level based on count
                if count == 0 {
                    level = 0
                } else if count <= 3 {
                    level = 1
                } else if count <= 6 {
                    level = 2
                } else if count <= 10 {
                    level = 3
                } else {
                    level = 4
                }

                totalContributions += count
                days.append(ContributionDay(date: date, count: count, level: level))
            }

            weeks.insert(ContributionWeek(days: days), at: 0)
        }

        return ContributionData(weeks: weeks, totalContributions: totalContributions, username: username)
    }

    private func parseContributionData(_ data: Data) throws -> ContributionData {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataDict = json?["data"] as? [String: Any],
              let user = dataDict["user"] as? [String: Any],
              let contributionsCollection = user["contributionsCollection"] as? [String: Any],
              let calendar = contributionsCollection["contributionCalendar"] as? [String: Any],
              let totalContributions = calendar["totalContributions"] as? Int,
              let weeksArray = calendar["weeks"] as? [[String: Any]] else {
            throw GitHubError.invalidResponse
        }

        let dateFormatter = ISO8601DateFormatter()

        let weeks = weeksArray.map { weekDict -> ContributionWeek in
            guard let daysArray = weekDict["contributionDays"] as? [[String: Any]] else {
                return ContributionWeek(days: [])
            }

            let days = daysArray.compactMap { dayDict -> ContributionDay? in
                guard let dateString = dayDict["date"] as? String,
                      let count = dayDict["contributionCount"] as? Int,
                      let levelString = dayDict["contributionLevel"] as? String,
                      let date = dateFormatter.date(from: dateString + "T00:00:00Z") else {
                    return nil
                }

                let level = contributionLevelToInt(levelString)
                return ContributionDay(date: date, count: count, level: level)
            }

            return ContributionWeek(days: days)
        }

        // Get username from somewhere - for now use a default
        return ContributionData(weeks: weeks, totalContributions: totalContributions, username: "GitHub User")
    }

    private func contributionLevelToInt(_ level: String) -> Int {
        switch level {
        case "NONE": return 0
        case "FIRST_QUARTILE": return 1
        case "SECOND_QUARTILE": return 2
        case "THIRD_QUARTILE": return 3
        case "FOURTH_QUARTILE": return 4
        default: return 0
        }
    }

    private func getGitHubToken() -> String? {
        // First try to get from environment variable
        if let token = ProcessInfo.processInfo.environment[tokenKey], !token.isEmpty {
            return token
        }

        // Try to get from UserDefaults
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            return token
        }

        return nil
    }

    func saveGitHubToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
}
