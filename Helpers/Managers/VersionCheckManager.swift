//
//  VersionCheckManager.swift
//  animation
//
//  Created on 10/11/25.
//
import Foundation
import SwiftUI

class VersionCheckManager {
    let itunesLookupURLString = "https://itunes.apple.com/lookup?bundleID"
    @MainActor static let shared = VersionCheckManager()

    var bundleID: String? {
        Bundle.main.bundleIdentifier
    }

    func checkIfAppUpdateAvailable() async -> ReturnResult? {
        do {
            guard let bundleID,
                  let lookupURL = URL(string: "\(itunesLookupURLString)=\(bundleID)")
            else {
                return nil
            }
            let data = try await URLSession.shared.data(from: lookupURL).0
            guard let rawJSON = try (JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return nil
            }
            print(rawJSON)
            return nil
        } catch {
            print("Error: \(error)")
            return nil
        }
    }

    struct ReturnResult: Identifiable {
        private(set) var id: String = UUID().uuidString
        var currentVersion: String
        var availableVersion: String
        var releaseNotes: String?
        var appLogo: String
        var appURL: String
    }

    private func parseJSON(_ rawJSON: [String: Any]) -> ReturnResult? {
        guard let jsonResults = rawJSON["results"] as? [Any] else { return nil }
        guard let jsonValue = jsonResults.first as? [String: Any] else { return nil }

        guard let availbleVersion = jsonValue["version"] as? String,
              let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let appLogo = jsonValue["artworkUrl512"] as? String,
              let trackViewUrl = (jsonValue["trackViewUrl"] as? String)?.components(separatedBy: "?").first,
              let releaseNotes = jsonValue["releaseNotes"] as? String
        else {
            return nil
        }

        if currentVersion
            .compare(availbleVersion, options: .numeric) == .orderedAscending
        {
            return .init(
                currentVersion: currentVersion,
                availableVersion: availbleVersion,
                releaseNotes: releaseNotes,
                appLogo: appLogo,
                appURL: trackViewUrl
            )
        }

        return nil
    }
}
