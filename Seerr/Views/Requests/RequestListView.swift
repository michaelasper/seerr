import SwiftUI

struct RequestListView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var viewModel: RequestListViewModel
    let onOpenSettings: () -> Void

    var body: some View {
        Group {
            if !settings.isConfigured {
                UnconfiguredView(onOpenSettings: onOpenSettings)
            } else if viewModel.requests.isEmpty && viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading requests…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.requests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No requests to show")
                        .font(.headline)
                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(viewModel.requests) { request in
                    NavigationLink {
                        if let tmdbId = request.media?.tmdbId {
                            MediaDetailView(mediaType: request.media?.mediaType ?? request.type, tmdbId: tmdbId, initialDetail: viewModel.detail(for: request))
                        } else {
                            Text("Missing media id")
                        }
                    } label: {
                        RequestRow(
                            request: request,
                            detail: viewModel.detail(for: request),
                            onAppear: {
                                Task { await viewModel.fetchDetailIfNeeded(for: request) }
                            }
                        )
                    }
                }
                .listStyle(.plain)
                .refreshable { await viewModel.reload(using: settings) }
            }
        }
        .animation(.default, value: viewModel.requests.count)
    }
}

private struct UnconfiguredView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("No connection configured.")
                .font(.headline)
            Text("Open settings to reconnect to Overseerr.")
                .foregroundStyle(.secondary)
            Button("Open settings", action: onOpenSettings)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
