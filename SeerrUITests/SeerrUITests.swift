import XCTest

final class SeerrUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testConfigureAndLoadsRequests() throws {
        let fileEnv = loadEnvFile()
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-reset")
        let env = ProcessInfo.processInfo.environment
        let useRealOverseerr = env["USE_REAL_OVERSEERR"] == "1"
            || ((env["OVERSEERR_BASE_URL"] ?? fileEnv["OVERSEERR_BASE_URL"])?.isEmpty == false
                && (env["OVERSEERR_API_KEY"] ?? fileEnv["OVERSEERR_API_KEY"])?.isEmpty == false)
        if !useRealOverseerr {
            app.launchEnvironment["UI_TEST_MODE"] = "1"
        } else {
            app.launchEnvironment["USE_REAL_OVERSEERR"] = "1"
            app.launchEnvironment["UI_TEST_MODE"] = "0"
        }
        if let base = env["OVERSEERR_BASE_URL"] ?? fileEnv["OVERSEERR_BASE_URL"] {
            app.launchEnvironment["OVERSEERR_BASE_URL"] = base
        }
        if let key = env["OVERSEERR_API_KEY"] ?? fileEnv["OVERSEERR_API_KEY"] {
            app.launchEnvironment["OVERSEERR_API_KEY"] = key
        }
        if let accent = env["OVERSEERR_ACCENT_COLOR"] ?? fileEnv["OVERSEERR_ACCENT_COLOR"] {
            app.launchEnvironment["OVERSEERR_ACCENT_COLOR"] = accent
        }
        app.launch()

        if useRealOverseerr {
            let connectTitle = app.staticTexts["Connect to Overseerr"]
            if connectTitle.waitForExistence(timeout: 2) {
                let baseField = app.textFields["baseURLField"]
                if baseField.waitForExistence(timeout: 2) {
                    clearAndType(baseField, text: app.launchEnvironment["OVERSEERR_BASE_URL"] ?? "")
                }
                let apiKeyField = app.secureTextFields["apiKeyField"]
                if apiKeyField.waitForExistence(timeout: 2) {
                    clearAndType(apiKeyField, text: app.launchEnvironment["OVERSEERR_API_KEY"] ?? "")
                }
                app.buttons["Connect"].tap()
            }
            XCTAssertTrue(app.tabBars.buttons["Requests"].waitForExistence(timeout: 8))
        } else {
            let connectTitle = app.staticTexts["Connect to Overseerr"]
            XCTAssertTrue(connectTitle.waitForExistence(timeout: 3))

            let baseField = app.textFields["baseURLField"]
            XCTAssertTrue(baseField.waitForExistence(timeout: 2))
            clearAndType(baseField, text: app.launchEnvironment["OVERSEERR_BASE_URL"] ?? "https://mock.overseerr")

            let apiKeyField = app.secureTextFields["apiKeyField"]
            clearAndType(apiKeyField, text: app.launchEnvironment["OVERSEERR_API_KEY"] ?? "dummy-api-key")

            app.buttons["Connect"].tap()

            let johnWick = app.staticTexts["John Wick: Chapter 4"]
            XCTAssertTrue(johnWick.waitForExistence(timeout: 5))

            let office = app.staticTexts["The Office"]
            XCTAssertTrue(office.waitForExistence(timeout: 5))

            XCTAssertTrue(app.staticTexts["Approved"].exists)
        }
    }

    func testDiscoverSearchAndFilters() throws {
        let fileEnv = loadEnvFile()
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-reset")
        let env = ProcessInfo.processInfo.environment
        let useRealOverseerr = env["USE_REAL_OVERSEERR"] == "1"
            || ((env["OVERSEERR_BASE_URL"] ?? fileEnv["OVERSEERR_BASE_URL"])?.isEmpty == false
                && (env["OVERSEERR_API_KEY"] ?? fileEnv["OVERSEERR_API_KEY"])?.isEmpty == false)
        if !useRealOverseerr {
            app.launchEnvironment["UI_TEST_MODE"] = "1"
        } else {
            app.launchEnvironment["USE_REAL_OVERSEERR"] = "1"
            app.launchEnvironment["UI_TEST_MODE"] = "0"
        }
        if let base = env["OVERSEERR_BASE_URL"] ?? fileEnv["OVERSEERR_BASE_URL"] {
            app.launchEnvironment["OVERSEERR_BASE_URL"] = base
        }
        if let key = env["OVERSEERR_API_KEY"] ?? fileEnv["OVERSEERR_API_KEY"] {
            app.launchEnvironment["OVERSEERR_API_KEY"] = key
        }
        if let accent = env["OVERSEERR_ACCENT_COLOR"] ?? fileEnv["OVERSEERR_ACCENT_COLOR"] {
            app.launchEnvironment["OVERSEERR_ACCENT_COLOR"] = accent
        }
        app.launch()

        // Complete setup if needed.
        let connectTitle = app.staticTexts["Connect to Overseerr"]
        if connectTitle.waitForExistence(timeout: 2) {
            let baseField = app.textFields["baseURLField"]
            if baseField.waitForExistence(timeout: 2) {
                clearAndType(baseField, text: app.launchEnvironment["OVERSEERR_BASE_URL"] ?? "https://mock.overseerr")
            }
            let apiKeyField = app.secureTextFields["apiKeyField"]
            if apiKeyField.waitForExistence(timeout: 2) {
                clearAndType(apiKeyField, text: app.launchEnvironment["OVERSEERR_API_KEY"] ?? "dummy-api-key")
            }
            app.buttons["Connect"].tap()
        }

        app.tabBars.buttons["Discover"].tap()
        let searchField = app.searchFields["Search movies & TV"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 4))

        if useRealOverseerr {
            // Smoke check: filters exist and search can be focused.
            XCTAssertTrue(app.textFields["Genre id"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.textFields["Year"].waitForExistence(timeout: 2))
            searchField.tap()
            searchField.typeText("matrix")
        } else {
            // Mocked expectations.
            XCTAssertTrue(app.staticTexts["Trending"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["Popular Movies"].exists)
            XCTAssertTrue(app.staticTexts["Popular Series"].exists)

            searchField.tap()
            searchField.typeText("john")

            let johnWick = app.staticTexts["John Wick: Chapter 4"]
            XCTAssertTrue(johnWick.waitForExistence(timeout: 3))

            // Apply filters and ensure content still loads.
            let genreField = app.textFields["Genre id"]
            let yearField = app.textFields["Year"]
            if genreField.exists { clearAndType(genreField, text: "28") }
            if yearField.exists { clearAndType(yearField, text: "2023") }
            app.buttons["Apply"].tap()
            XCTAssertTrue(johnWick.waitForExistence(timeout: 3))
        }
    }

    private func clearAndType(_ element: XCUIElement, text: String) {
        element.tap()
        if let existing = element.value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            element.typeText(deleteString)
        }
        element.typeText(text)
    }

    private func loadEnvFile() -> [String: String] {
        let currentFile = URL(fileURLWithPath: #filePath)
        let repoRoot = currentFile.deletingLastPathComponent() // SeerrUITests
            .deletingLastPathComponent() // project root
        let candidates = [
            repoRoot.appending(path: ".env.local"),
            repoRoot.appending(path: "Seerr/Resources/.env.local")
        ]
        guard let envURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }),
              let content = try? String(contentsOf: envURL) else { return [:] }
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
