//
//  UpdateChecker.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import AppKit

/// Checks for app updates via GitHub Releases API.
/// Zero dependencies — uses URLSession to query the latest release.
@Observable
final class UpdateChecker {
    
    // MARK: - Configuration
    
    /// GitHub repository in "owner/repo" format
    private let githubRepo = "thanhtaivtt/AI-Translator-App"
    
    /// How often to check (in seconds). Default: every 6 hours.
    private let checkInterval: TimeInterval = 6 * 60 * 60
    
    /// UserDefaults key for last check timestamp
    private let lastCheckKey = "lastUpdateCheck"
    
    // MARK: - State
    
    var updateAvailable: Bool = false
    var latestVersion: String = ""
    var releaseURL: String = ""
    var releaseNotes: String = ""
    
    // MARK: - Public
    
    /// Check for updates (respects check interval to avoid spamming API).
    func checkForUpdates(force: Bool = false) {
        let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
        let now = Date().timeIntervalSince1970
        
        // Skip if checked recently (unless forced)
        if !force && (now - lastCheck) < checkInterval {
            return
        }
        
        Task {
            await performCheck()
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
        }
    }
    
    /// Show the update alert if an update is available.
    @MainActor
    func showUpdateAlertIfNeeded() {
        guard updateAvailable else { return }
        
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "AI Translator \(latestVersion) is available. You are currently running \(currentVersion).\n\n\(releaseNotes)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "Skip This Version")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            // Open download page
            if let url = URL(string: releaseURL) {
                NSWorkspace.shared.open(url)
            }
        case .alertThirdButtonReturn:
            // Skip this version
            UserDefaults.standard.set(latestVersion, forKey: "skippedVersion")
            updateAvailable = false
        default:
            break
        }
    }
    
    // MARK: - Private
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    private func performCheck() async {
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }
            
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            // Extract version from tag (remove "v" prefix)
            let remoteVersion = release.tagName.hasPrefix("v")
                ? String(release.tagName.dropFirst())
                : release.tagName
            
            // Skip pre-releases
            if release.prerelease { return }
            
            // Skip if user chose to skip this version
            let skippedVersion = UserDefaults.standard.string(forKey: "skippedVersion")
            if skippedVersion == remoteVersion { return }
            
            // Compare versions
            if isVersion(remoteVersion, newerThan: currentVersion) {
                await MainActor.run {
                    self.latestVersion = remoteVersion
                    self.releaseURL = release.htmlUrl
                    self.releaseNotes = extractFirstLines(from: release.body ?? "", maxLines: 5)
                    self.updateAvailable = true
                }
            }
        } catch {
            // Silently fail — update check is best-effort
            print("[UpdateChecker] Check failed: \(error.localizedDescription)")
        }
    }
    
    /// Semantic version comparison: returns true if `version` > `current`
    private func isVersion(_ version: String, newerThan current: String) -> Bool {
        let v1 = version.split(separator: ".").compactMap { Int($0) }
        let v2 = current.split(separator: ".").compactMap { Int($0) }
        
        let maxLen = max(v1.count, v2.count)
        for i in 0..<maxLen {
            let a = i < v1.count ? v1[i] : 0
            let b = i < v2.count ? v2[i] : 0
            if a > b { return true }
            if a < b { return false }
        }
        return false
    }
    
    /// Extract first N lines from release notes for display
    private func extractFirstLines(from text: String, maxLines: Int) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(maxLines)
        return lines.joined(separator: "\n")
    }
}

// MARK: - GitHub API Models

private struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let prerelease: Bool
    let publishedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body
        case htmlUrl = "html_url"
        case prerelease
        case publishedAt = "published_at"
    }
}
