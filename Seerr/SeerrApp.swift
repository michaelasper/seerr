import SwiftUI

@main
struct SeerrApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var requestListViewModel = RequestListViewModel()

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("--ui-testing-reset"),
           let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        MockServer.enableIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(requestListViewModel)
        }
    }
}
