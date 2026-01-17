//
//  NotchView.swift
//  gitisland
//
//  The main dynamic island SwiftUI view
//

import AppKit
import SwiftUI

private let cornerRadiusInsets = (
    opened: (top: CGFloat(19), bottom: CGFloat(24)),
    closed: (top: CGFloat(6), bottom: CGFloat(14))
)

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @StateObject private var githubService = GitHubService()
    @State private var isVisible: Bool = false
    @State private var isHovering: Bool = false
    @State private var hoveredDay: ContributionDay?
    @State private var tooltipPosition: CGPoint = .zero

    private var closedNotchSize: CGSize {
        CGSize(
            width: viewModel.deviceNotchRect.width,
            height: viewModel.deviceNotchRect.height
        )
    }

    private var notchSize: CGSize {
        switch viewModel.status {
        case .closed:
            return closedNotchSize
        case .opened:
            return viewModel.openedSize
        }
    }

    private var topCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.top
            : cornerRadiusInsets.closed.top
    }

    private var bottomCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.bottom
            : cornerRadiusInsets.closed.bottom
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                notchLayout
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        alignment: .top
                    )
                    .padding(
                        .horizontal,
                        viewModel.status == .opened
                            ? 12
                            : cornerRadiusInsets.closed.bottom
                    )
                    .padding(.bottom, viewModel.status == .opened ? 16 : 0)
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (viewModel.status == .opened || isHovering) ? .black.opacity(0.7) : .clear,
                        radius: 6
                    )
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        maxHeight: viewModel.status == .opened ? notchSize.height : nil,
                        alignment: .top
                    )
                    .animation(viewModel.status == .opened ? openAnimation : closeAnimation, value: viewModel.status)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            isHovering = hovering
                        }
                    }
                    .onTapGesture {
                        if viewModel.status != .opened {
                            viewModel.notchOpen()
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Tooltip overlay - rendered outside the clipped notch area using global coordinates
            if let day = hoveredDay {
                ContributionTooltipView(day: day)
                    .position(tooltipPosition)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeOut(duration: 0.15), value: hoveredDay?.id)
                    .zIndex(10000)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .preferredColorScheme(.dark)
        .onAppear {
            if !viewModel.hasPhysicalNotch {
                isVisible = true
            }
        }
        .onChange(of: viewModel.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
    }

    @ViewBuilder
    private var notchLayout: some View {
        VStack(alignment: .center, spacing: 0) {
            // Header row - always present, maintains consistent structure
            HStack(spacing: 8) {
                Spacer()
            }
            .frame(height: max(24, closedNotchSize.height))
            .frame(width: viewModel.status == .opened ? notchSize.width - 24 : closedNotchSize.width - 20)

            // Main content - only when opened
            if viewModel.status == .opened {
                VStack(spacing: 0) {
                    if let error = githubService.error {
                        VStack(spacing: 8) {
                            Text("Failed to load contributions")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            Text(errorMessage(for: error))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                    } else if let contributionData = githubService.contributionData {
                        ContributionGraphView(
                            data: contributionData,
                            hoveredDay: $hoveredDay,
                            tooltipPosition: $tooltipPosition
                        )
                        .padding(.top, 8)
                    }
                }
                .frame(width: notchSize.width - 24)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top)
                            .combined(with: .opacity)
                            .animation(.smooth(duration: 0.35)),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    )
                )
            }
        }
    }

    private func handleStatusChange(from oldStatus: NotchStatus, to newStatus: NotchStatus) {
        switch newStatus {
        case .opened:
            isVisible = true
            // Fetch GitHub contributions when notch opens
            Task {
                await githubService.fetchContributions(username: "srbsingh3")
            }
        case .closed:
            guard viewModel.hasPhysicalNotch else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if viewModel.status == .closed {
                    isVisible = false
                }
            }
        }
    }

    private func errorMessage(for error: GitHubError) -> String {
        switch error {
        case .noToken:
            return "GitHub token not found. Set GITHUB_TOKEN environment variable or configure in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .decodingError:
            return "Failed to parse GitHub data"
        }
    }
}
