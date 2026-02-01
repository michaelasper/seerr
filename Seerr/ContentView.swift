import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var viewModel: RequestListViewModel

    @State private var showingSettings = false
    @State private var showingSetup = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                RequestListView(viewModel: viewModel, onOpenSettings: { showingSettings = true })
                    .navigationTitle("Requests")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
            .tabItem { Label("Requests", systemImage: "tray.full") }
            .tag(0)

            NavigationStack {
                DiscoverView()
            }
            .tabItem { Label("Discover", systemImage: "sparkles.tv") }
            .tag(1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .task {
            guard settings.isConfigured else { return }
            await viewModel.reload(using: settings)
        }
        .onChange(of: settings.baseURLString) { _ in
            guard settings.isConfigured else { return }
            Task { await viewModel.reload(using: settings) }
        }
        .onChange(of: settings.apiKey) { _ in
            guard settings.isConfigured else { return }
            Task { await viewModel.reload(using: settings) }
        }
        .onChange(of: settings.isConfigured) { isConfigured in
            showingSetup = !isConfigured
            if isConfigured {
                Task { await viewModel.reload(using: settings) }
            }
        }
        .onAppear {
            showingSetup = !settings.isConfigured
        }
        .fullScreenCover(isPresented: $showingSetup) {
            SetupFlowView {
                showingSetup = false
                Task { await viewModel.reload(using: settings) }
            }
            .environmentObject(settings)
        }
    }
}
