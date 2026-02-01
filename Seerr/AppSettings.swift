import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let baseURL = "overseerr.baseUrl"
        static let apiKey = "overseerr.apiKey"
        static let accentColorHex = "overseerr.accentColorHex"
    }

    @Published var baseURLString: String {
        didSet { persist() }
    }

    @Published var apiKey: String {
        didSet { persist() }
    }

    @Published var accentColorHex: String {
        didSet { persist() }
    }

    init(baseURLString: String? = nil,
         apiKey: String? = nil,
         accentColorHex: String? = nil) {
        let env = EnvLoader.load()
        self.baseURLString = baseURLString
            ?? UserDefaults.standard.string(forKey: Keys.baseURL)
            ?? env["OVERSEERR_BASE_URL"]
            ?? ""
        self.apiKey = apiKey
            ?? UserDefaults.standard.string(forKey: Keys.apiKey)
            ?? env["OVERSEERR_API_KEY"]
            ?? ""
        self.accentColorHex = accentColorHex
            ?? UserDefaults.standard.string(forKey: Keys.accentColorHex)
            ?? env["OVERSEERR_ACCENT_COLOR"]
            ?? "#1a99de"
    }

    var baseURL: URL? {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let hasScheme = trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://")
        let prepared = hasScheme ? trimmed : "https://\(trimmed)"
        return URL(string: prepared)
    }

    var isConfigured: Bool {
        baseURL != nil && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func update(baseURLString: String, apiKey: String) {
        self.baseURLString = baseURLString
        self.apiKey = apiKey
    }

    var accentColor: Color {
        Color(hex: accentColorHex) ?? Color.accentColor
    }

    private func persist() {
        UserDefaults.standard.set(baseURLString, forKey: Keys.baseURL)
        UserDefaults.standard.set(apiKey, forKey: Keys.apiKey)
        UserDefaults.standard.set(accentColorHex, forKey: Keys.accentColorHex)
    }
}

private enum EnvLoader {
    static func load() -> [String: String] {
        let env = ProcessInfo.processInfo.environment
        let inline = inlineEnv(env)

        var fileEnv: [String: String] = [:]
        if let url = Bundle.main.url(forResource: ".env.local", withExtension: nil),
           let parsed = parse(fileURL: url) {
            fileEnv = parsed
        }

        let hasRealCreds = (inline["OVERSEERR_BASE_URL"]?.isEmpty == false && inline["OVERSEERR_API_KEY"]?.isEmpty == false)
            || (fileEnv["OVERSEERR_BASE_URL"]?.isEmpty == false && fileEnv["OVERSEERR_API_KEY"]?.isEmpty == false)
            || env["USE_REAL_OVERSEERR"] == "1"

        if env["UI_TEST_MODE"] == "1" && !hasRealCreds {
            return [:]
        }

        return fileEnv.merging(inline) { _, new in new }
    }

    private static func inlineEnv(_ env: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        ["OVERSEERR_BASE_URL", "OVERSEERR_API_KEY", "OVERSEERR_ACCENT_COLOR"].forEach { key in
            if let value = env[key], !value.isEmpty {
                result[key] = value
            }
        }
        return result
    }

    private static func parse(fileURL: URL) -> [String: String]? {
        guard let content = try? String(contentsOf: fileURL) else { return nil }
        var result: [String: String] = [:]
        for line in content.split(whereSeparator: { $0.isNewline }) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), let separator = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty else { continue }
            result[key] = value
        }
        return result
    }
}
