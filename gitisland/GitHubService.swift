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

        // Check if we have a token, otherwise use mock data
        guard let token = getGitHubToken() else {
            // Fallback to mock data if no token
            contributionData = generateMockData(username: username)
            isLoading = false
            return
        }

        let query = """
        query($userName:String!) {
          user(login: $userName){
            contributionsCollection {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                    contributionLevel
                  }
                }
              }
            }
          }
        }
        """

        let body: [String: Any] = [
            "query": query,
            "variables": ["userName": username]
        ]

        guard let url = URL(string: "https://api.github.com/graphql") else {
            error = .invalidURL
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                error = .invalidResponse
                isLoading = false
                return
            }

            contributionData = try parseContributionData(data, username: username)
            isLoading = false
        } catch let decodingError as DecodingError {
            error = .decodingError(decodingError)
            isLoading = false
        } catch {
            self.error = .networkError(error)
            isLoading = false
        }
    }

    private func generateMockData(username: String) -> ContributionData {
        // Real contribution data fetched from https://github.com/srbsingh3
        // Last 154 days (22 weeks), fetched on 2026-01-17
        // Total contributions: 625
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Actual contribution counts and levels from GitHub
        let activityDays: [String: (count: Int, level: Int)] = [
            "2025-08-24": (50, 4),
            "2025-08-31": (1, 1),
            "2025-09-06": (13, 2),
            "2025-09-07": (3, 1),
            "2025-09-22": (2, 1),
            "2025-11-02": (3, 1),
            "2025-11-03": (1, 1),
            "2025-11-04": (10, 1),
            "2025-11-05": (5, 1),
            "2025-11-11": (2, 1),
            "2025-11-12": (7, 1),
            "2025-11-13": (32, 4),
            "2025-11-14": (7, 1),
            "2025-11-15": (2, 1),
            "2025-11-16": (2, 1),
            "2025-11-17": (7, 1),
            "2025-11-18": (3, 1),
            "2025-11-19": (4, 1),
            "2025-11-22": (5, 1),
            "2025-11-25": (1, 1),
            "2025-11-28": (21, 3),
            "2025-11-29": (8, 1),
            "2025-11-30": (25, 3),
            "2025-12-02": (14, 2),
            "2025-12-21": (11, 2),
            "2025-12-22": (13, 2),
            "2025-12-23": (12, 2),
            "2025-12-24": (10, 1),
            "2025-12-25": (22, 3),
            "2025-12-26": (21, 3),
            "2025-12-27": (22, 3),
            "2025-12-28": (1, 1),
            "2025-12-29": (3, 1),
            "2025-12-31": (6, 1),
            "2026-01-01": (13, 2),
            "2026-01-02": (12, 2),
            "2026-01-03": (3, 1),
            "2026-01-04": (26, 3),
            "2026-01-05": (13, 2),
            "2026-01-06": (13, 2),
            "2026-01-07": (37, 4),
            "2026-01-08": (40, 4),
            "2026-01-09": (21, 3),
            "2026-01-10": (16, 2),
            "2026-01-11": (10, 1),
            "2026-01-12": (2, 1),
            "2026-01-13": (2, 1),
            "2026-01-14": (9, 1),
            "2026-01-15": (26, 3),
            "2026-01-16": (23, 3),
            "2026-01-17": (10, 1),
        ]

        var weeks: [ContributionWeek] = []
        var totalContributions = 0

        // Start date: 2025-08-17 (Sunday)
        guard let startDate = dateFormatter.date(from: "2025-08-17") else {
            return ContributionData(weeks: [], totalContributions: 0, username: username)
        }

        // Generate 22 weeks of data, each week from Sunday to Saturday
        for weekIndex in 0..<22 {
            var days: [ContributionDay] = []

            for dayOfWeek in 0..<7 { // 0 = Sunday, 6 = Saturday
                let dayOffset = weekIndex * 7 + dayOfWeek
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

                let dateString = dateFormatter.string(from: date)

                // Get contribution data for this date
                let (count, level) = activityDays[dateString] ?? (0, 0)

                totalContributions += count
                days.append(ContributionDay(date: date, count: count, level: level))
            }

            weeks.append(ContributionWeek(days: days))
        }

        return ContributionData(weeks: weeks, totalContributions: totalContributions, username: username)
    }

    private func parseContributionData(_ data: Data, username: String) throws -> ContributionData {
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

        // Only take the last 22 weeks (5 months) to match our design
        let recentWeeks = weeksArray.suffix(22)

        let weeks = recentWeeks.map { weekDict -> ContributionWeek in
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

        return ContributionData(weeks: Array(weeks), totalContributions: totalContributions, username: username)
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
