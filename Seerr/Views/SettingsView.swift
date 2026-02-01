import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var baseURL: String = ""
    @State private var apiKey: String = ""
    @State private var accentHex: String = ""
    @State private var currentUser: CurrentUser?
    @State private var isLoadingUser = false
    @State private var userError: String?
    @State private var showAdvanced = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Overseerr Server") {
                    TextField("https://overseerr.yourdomain.com", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .accessibilityIdentifier("baseURLField")
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .accessibilityIdentifier("apiKeyField")
                }

                Section("Theme") {
                    Text("Accent color")
                    TextField("#1a99de", text: $accentHex)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .keyboardType(.default)
                }

                Section("Profile") {
                    if isLoadingUser {
                        ProgressView()
                    } else if let error = userError {
                        Text(error).foregroundStyle(.secondary)
                    } else if let user = currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name).font(.headline)
                            if let email = user.email {
                                Text(email).font(.subheadline).foregroundStyle(.secondary)
                            }
                            if let roles = user.roles, !roles.isEmpty {
                                Text("Roles: \(roles.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !user.permissionLabels.isEmpty {
                                Text("Permissions: \(user.permissionLabels.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Profile not loaded yet").foregroundStyle(.secondary)
                    }

                    Button("Refresh profile", action: refreshProfile)
                        .buttonStyle(.borderless)
                        .disabled(isLoadingUser || !settings.isConfigured)

                    Button("Clear saved server & profile", role: .destructive) {
                        resetSettings()
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $showAdvanced) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Switch profiles by pasting a different API key. Changes are saved when you tap Save.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("API keys are stored only on-device in UserDefaults.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text("Advanced")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
                .onAppear {
                    baseURL = settings.baseURLString
                    apiKey = settings.apiKey
                    accentHex = settings.accentColorHex
                    refreshProfile()
                }
        }
    }

    private var canSave: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        settings.update(baseURLString: baseURL, apiKey: apiKey)
        settings.accentColorHex = accentHex
        refreshProfile()
        dismiss()
    }

    private func refreshProfile() {
        guard settings.isConfigured else { return }
        isLoadingUser = true
        userError = nil
        Task {
            do {
                let api = OverseerrAPI(configuration: .init(baseURL: settings.baseURL!, apiKey: settings.apiKey))
                let user = try await api.fetchCurrentUser()
                await MainActor.run {
                    currentUser = user
                    isLoadingUser = false
                }
            } catch {
                await MainActor.run {
                    userError = error.localizedDescription
                    isLoadingUser = false
                }
            }
        }
    }

    private func resetSettings() {
        baseURL = ""
        apiKey = ""
        accentHex = "#1a99de"
        settings.update(baseURLString: "", apiKey: "")
        settings.accentColorHex = accentHex
        currentUser = nil
    }
}
