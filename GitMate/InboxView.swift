//  InboxView.swift
//  GitMate
//
//  Created by somil jain on 04/08/26.
//

import SwiftUI
import Combine

struct InboxView: View {
    @ObservedObject var viewModel: InboxViewModel
    @EnvironmentObject private var session: SessionStore
    
    @State private var selectedFilter: InboxFilter = .all
    @State private var selectedPR: PullRequestReference?
    
    private var filteredNotifications: [InboxNotification] {
        switch selectedFilter {
        case .all: return viewModel.notifications
        case .issues: return viewModel.notifications.filter { $0.kind.isIssue }
        case .pullRequests: return viewModel.notifications.filter { $0.kind.isPullRequest }
        case .unread: return viewModel.notifications.filter { $0.isUnread }
        case .read: return viewModel.notifications.filter { !$0.isUnread }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                HStack(alignment: .bottom) {
                    Text("Inbox")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Mark all read") {
                        Task {
                            await viewModel.markAllAsRead(token: session.savedAccessKey)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(viewModel.hasUnreadNotifications ? Color.cyan : Color.white.opacity(0.3))
                    .disabled(!viewModel.hasUnreadNotifications)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InboxFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(
                                        selectedFilter == filter
                                        ? Color.cyan
                                        : Color.white.opacity(0.7)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(
                                                selectedFilter == filter
                                                ? Color.cyan.opacity(0.15)
                                                : Color.white.opacity(0.05)
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedFilter == filter
                                                ? Color.cyan.opacity(0.5)
                                                : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.cyan)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if filteredNotifications.isEmpty {
                    VStack(spacing: 8) {
                        Text(viewModel.emptyStateMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Retry Fetch") {
                            Task {
                                await viewModel.fetchNotifications(token: session.savedAccessKey)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(filteredNotifications) { notification in
                            if notification.kind.isPullRequest, let owner = notification.owner, let number = notification.prNumber {
                                Button {
                                    selectedPR = PullRequestReference(owner: owner, repository: notification.repo, number: number)
                                } label: {
                                    InboxCardView(notification: notification)
                                }
                                .buttonStyle(.plain)
                            } else {
                                InboxCardView(notification: notification)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
            }
        }
        .refreshable {
            await viewModel.fetchNotifications(token: session.savedAccessKey, isRefresh: true)
        }
        .task(id: session.savedAccessKey) {
            await viewModel.fetchNotifications(token: session.savedAccessKey)
        }
        .sheet(item: $selectedPR) { ref in
            NavigationStack {
                PullRequestDetailView(reference: ref, token: session.savedAccessKey)
            }
            .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var notifications: [InboxNotification] = []
    @Published var isLoading = false
    @Published var emptyStateMessage: String = "No notifications found."
    
    var hasUnreadNotifications: Bool {
        notifications.contains(where: { $0.isUnread })
    }
    
    func markAllAsRead(token: String?) async {
        guard let token = token, !token.isEmpty else { return }
        
        let previousNotifications = notifications
        withAnimation {
            notifications = notifications.map { notif in
                var updated = notif
                updated.isUnread = false
                return updated
            }
        }
        
        guard let url = URL(string: "https://api.github.com/notifications") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitMate-App", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let body: [String: Any] = [
            "read": true,
            "last_read_at": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("GitHub API error while marking notifications as read.")
                withAnimation {
                    self.notifications = previousNotifications
                }
                return
            }
            print("Successfully marked all notifications as read on GitHub.")
        } catch {
            print("Network error marking notifications as read: \(error)")
            withAnimation {
                self.notifications = previousNotifications
            }
        }
    }
    
    func fetchNotifications(token: String?, isRefresh: Bool = false) async {
        guard let token = token, !token.isEmpty else {
            emptyStateMessage = "Missing access token. Please sign in again."
            print("InboxViewModel: Token is missing or empty in SessionStore.")
            return
        }
        
        let tokenType = classifyToken(token)
        print("Inbox token type guess: \(tokenType)")
        printTokenSupportHint(for: tokenType)
        
        if !isRefresh {
            isLoading = true
        }
        defer {
            if !isRefresh {
                isLoading = false
            }
        }
        
        guard let url = URL(string: "https://api.github.com/notifications?all=true") else {
            emptyStateMessage = "Invalid notifications URL."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitMate-App", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("Request: \(request.httpMethod ?? "GET") \(url.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                emptyStateMessage = "Invalid server response."
                print("Response was not HTTPURLResponse.")
                return
            }
            
            logHTTPResponse(httpResponse, data: data)
            
            guard httpResponse.statusCode == 200 else {
                let apiError = try? JSONDecoder().decode(GitHubAPIErrorResponse.self, from: data)
                let apiMessage = apiError?.message ?? "HTTP \(httpResponse.statusCode)"
                let docURL = apiError?.documentationURL ?? "n/a"
                
                print("GitHub API error message: \(apiMessage)")
                print("Docs URL: \(docURL)")
                
                let authProbe = await probeAuthenticatedUser(token: token)
                emptyStateMessage = "GitHub error: \(apiMessage)\n\(authProbe)"
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let apiResponse = try decoder.decode([GitHubNotification].self, from: data)
                print("Decoded notifications count: \(apiResponse.count)")
                
                let mappedNotifications = await withTaskGroup(of: (Int, InboxNotification).self) { group in
                    for (index, apiNotif) in apiResponse.enumerated() {
                        group.addTask {
                            let kind = await self.fetchSubjectKind(for: apiNotif.subject, token: token)
                            
                            let formatter = ISO8601DateFormatter()
                            let date = formatter.date(from: apiNotif.updatedAt) ?? Date()
                            let relativeFormatter = RelativeDateTimeFormatter()
                            relativeFormatter.unitsStyle = .abbreviated
                            let timeString = relativeFormatter.localizedString(for: date, relativeTo: Date())
                            
                            let parts = apiNotif.repository.fullName.split(separator: "/")
                            let owner = !parts.isEmpty ? String(parts[0]) : nil
                            let childRepoName = parts.count > 1 ? String(parts[1]) : ""
                            
                            var prNumber: Int? = nil
                            if await kind.isPullRequest, let urlStr = apiNotif.subject.url, let url = URL(string: urlStr) {
                                if let numStr = url.lastPathComponent.components(separatedBy: "?").first, let num = Int(numStr) {
                                    prNumber = num
                                }
                            }
                            
                            let notification = InboxNotification(
                                id: apiNotif.id,
                                kind: kind,
                                title: apiNotif.subject.title,
                                time: timeString,
                                repo: childRepoName,
                                isUnread: apiNotif.unread,
                                owner: owner,
                                prNumber: prNumber
                            )
                            return (index, notification)
                        }
                    }
                    
                    var results = [(Int, InboxNotification)]()
                    for await result in group {
                        results.append(result)
                    }
                    
                    return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
                }
                
                self.notifications = mappedNotifications
                
                if self.notifications.isEmpty {
                    let authProbe = await probeAuthenticatedUser(token: token)
                    emptyStateMessage = """
                    No notifications found.
                    \(authProbe)
                    Possible causes: inbox is truly empty, notifications already cleared/read, or token/account context differs.
                    """
                } else {
                    emptyStateMessage = "No notifications found."
                }
                
            } catch {
                printDecodingError(error, rawData: data)
                emptyStateMessage = "Failed to decode notifications. Check debug logs."
                self.notifications = []
            }
        } catch {
            print("Network error while fetching notifications: \(error)")
            emptyStateMessage = "Network error: \(error.localizedDescription)"
            self.notifications = []
        }
    }
    
    private func fetchSubjectKind(for subject: GitHubNotification.Subject, token: String) async -> NotificationKind {
        let isPR = subject.type == "PullRequest"
        let isIssue = subject.type == "Issue"
        
        guard isPR || isIssue else {
            return .openIssue
        }
        
        guard let urlString = subject.url, let url = URL(string: urlString) else {
            let state = subject.state?.lowercased() ?? "open"
            if isPR {
                return (state == "merged" || state == "closed") ? .mergedPR : .openPR
            } else {
                return (state == "closed") ? .closedIssue : .openIssue
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitMate-App", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return isPR ? .openPR : .openIssue
            }
            
            let detail = try JSONDecoder().decode(GitHubSubjectDetail.self, from: data)
            let state = detail.state?.lowercased() ?? "open"
            
            if isPR {
                if detail.draft == true {
                    return .draftPR
                } else if detail.merged == true || detail.mergedAt != nil {
                    return .mergedPR
                } else if state == "closed" {
                    return .closedPR
                } else {
                    return .openPR
                }
            } else {
                return (state == "closed") ? .closedIssue : .openIssue
            }
        } catch {
            return isPR ? .openPR : .openIssue
        }
    }
    
    private func logHTTPResponse(_ response: HTTPURLResponse, data: Data) {
        print("HTTP Status Code: \(response.statusCode)")
        print("Response Headers:")
        for (key, value) in response.allHeaderFields {
            print("   \(key): \(value)")
        }
        
        if let bodyString = String(data: data, encoding: .utf8) {
            print("Raw Response Body:\n\(bodyString)")
        } else {
            print("Raw Response Body: <non-UTF8 data, \(data.count) bytes>")
        }
    }
    
    private func printDecodingError(_ error: Error, rawData: Data) {
        print("JSON Decoding Error: \(error)")
        
        switch error {
        case let DecodingError.typeMismatch(type, context):
            print("typeMismatch(\(type)): \(context.debugDescription)")
            print("   codingPath: \(context.codingPath)")
        case let DecodingError.valueNotFound(type, context):
            print("valueNotFound(\(type)): \(context.debugDescription)")
            print("   codingPath: \(context.codingPath)")
        case let DecodingError.keyNotFound(key, context):
            print("keyNotFound(\(key)): \(context.debugDescription)")
            print("   codingPath: \(context.codingPath)")
        case let DecodingError.dataCorrupted(context):
            print("dataCorrupted: \(context.debugDescription)")
            print("   codingPath: \(context.codingPath)")
        default:
            break
        }
        
        if let bodyString = String(data: rawData, encoding: .utf8) {
            print("Raw body at decode failure:\n\(bodyString)")
        }
    }
    
    private func classifyToken(_ token: String) -> String {
        if token.hasPrefix("github_pat_") { return "fine-grained PAT" }
        if token.hasPrefix("ghp_") { return "classic PAT" }
        if token.hasPrefix("gho_") { return "OAuth app token" }
        if token.hasPrefix("ghu_") { return "GitHub App user-to-server token" }
        if token.hasPrefix("ghs_") { return "GitHub App installation token" }
        if token.hasPrefix("ghr_") { return "GitHub refresh token (not valid as API bearer token)" }
        return "unknown token type"
    }
    
    private func printTokenSupportHint(for tokenType: String) {
        switch tokenType {
        case "classic PAT":
            print("classic PAT usually works for /notifications with proper scopes (e.g. notifications / repo as needed).")
        case "fine-grained PAT":
            print("fine-grained PAT must include Notifications permission for the target account/resources.")
        case "GitHub App installation token":
            print("installation tokens are app-installation scoped and often unsuitable for user inbox /notifications.")
        case "GitHub App user-to-server token":
            print("user-to-server token may work only with proper user permissions granted via the app.")
        case "GitHub refresh token (not valid as API bearer token)":
            print("refresh token cannot be used directly as Authorization bearer token.")
        default:
            print("unknown token prefix; verify token origin and permissions.")
        }
    }
    
    private func probeAuthenticatedUser(token: String) async -> String {
        guard let url = URL(string: "https://api.github.com/user") else {
            return "Auth probe failed: invalid /user URL."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitMate-App", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return "Auth probe failed: non-HTTP response."
            }
            
            print("/user probe status: \(http.statusCode)")
            print("/user headers: \(http.allHeaderFields)")
            if let body = String(data: data, encoding: .utf8) {
                print("/user body: \(body)")
            }
            
            if http.statusCode == 200 {
                let user = try? JSONDecoder().decode(GitHubAuthenticatedUser.self, from: data)
                let login = user?.login ?? "unknown"
                return "Authenticated as @\(login)."
            } else {
                let apiError = try? JSONDecoder().decode(GitHubAPIErrorResponse.self, from: data)
                let message = apiError?.message ?? "HTTP \(http.statusCode)"
                return "Auth probe failed: \(message)."
            }
        } catch {
            return "Auth probe network error: \(error.localizedDescription)"
        }
    }
}

struct GitHubSubjectDetail: Codable {
    let state: String?
    let merged: Bool?
    let draft: Bool?
    let mergedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case state, merged, draft
        case mergedAt = "merged_at"
    }
}

enum InboxFilter: String, CaseIterable {
    case all = "All"
    case issues = "Issues"
    case pullRequests = "Pull Requests"
    case unread = "Unread"
    case read = "Read"
}

enum NotificationKind {
    case openPR
    case draftPR
    case mergedPR
    case closedPR
    case openIssue
    case closedIssue
    
    var iconName: String {
        switch self {
        case .openPR, .draftPR, .mergedPR, .closedPR:
            return "pull_request_icon"
        case .openIssue, .closedIssue:
            return "issue_icon"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .openPR, .openIssue:
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .mergedPR, .closedIssue:
            return Color(red: 0.55, green: 0.34, blue: 0.88)
        case .draftPR:
            return Color.gray
        case .closedPR:
            return Color(red: 0.86, green: 0.21, blue: 0.27)
        }
    }
    
    var isPullRequest: Bool {
        switch self {
        case .openPR, .draftPR, .mergedPR, .closedPR:
            return true
        default:
            return false
        }
    }
    
    var isIssue: Bool {
        switch self {
        case .openIssue, .closedIssue:
            return true
        default:
            return false
        }
    }
}

struct InboxNotification: Identifiable {
    let id: String
    let kind: NotificationKind
    let title: String
    let time: String
    let repo: String
    var isUnread: Bool
    let owner: String?
    let prNumber: Int?
}

struct InboxCardView: View {
    let notification: InboxNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(notification.kind.themeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(notification.kind.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(notification.kind.themeColor)
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 16, weight: notification.isUnread ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(notification.isUnread ? .white : .white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.system(size: 12))
                        .foregroundStyle(notification.isUnread ? Color.cyan : .white.opacity(0.5))
                        .fixedSize()
                }
                
                HStack(spacing: 8) {
                    Text(notification.repo.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(notification.isUnread ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            notification.isUnread
                            ? Color.cyan.opacity(0.15)
                            : Color.white.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    if notification.isUnread {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 6, height: 6)
                            .shadow(color: .cyan.opacity(0.8), radius: 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    notification.isUnread
                    ? Color(red: 0.12, green: 0.16, blue: 0.22)
                    : Color(red: 0.18, green: 0.22, blue: 0.29)
                )
        )
        .overlay(
            HStack {
                if notification.isUnread {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .cyan.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4)
                }
                Spacer()
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    notification.isUnread
                    ? Color.cyan.opacity(0.5)
                    : Color.white.opacity(0.1),
                    lineWidth: notification.isUnread ? 1.5 : 0.5
                )
        )
        .shadow(
            color: notification.isUnread ? Color.cyan.opacity(0.2) : Color.clear,
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()
        InboxView(viewModel: InboxViewModel())
    }
    .environmentObject(SessionStore())
}
