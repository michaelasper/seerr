import SwiftUI

struct SetupFlowView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var baseURL: String = ""
    @State private var apiKey: String = ""

    let onConnected: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("Connect to Overseerr")
                        .font(.largeTitle)
                        .bold()
                    Text("Enter your Overseerr URL and API key to get started.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    TextField("https://overseerr.yourdomain.com", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .accessibilityIdentifier("baseURLField")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .accessibilityIdentifier("apiKeyField")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                    Text("Find the API key in Overseerr: Settings → General → API Key.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                Button(action: connect) {
                    HStack {
                        Spacer()
                        Text("Connect")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(canConnect ? Color.accentColor : Color.accentColor.opacity(0.5))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canConnect)
                .padding(.horizontal)

                Spacer()
            }
            .interactiveDismissDisabled(true)
            .onAppear {
                baseURL = settings.baseURLString
                apiKey = settings.apiKey
            }
        }
    }

    private var canConnect: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func connect() {
        guard canConnect else { return }
        settings.update(baseURLString: baseURL, apiKey: apiKey)
        onConnected()
    }
}
