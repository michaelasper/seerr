import SwiftUI

struct MediaDetailView: View {
    @EnvironmentObject private var settings: AppSettings

    let mediaType: MediaType
    let tmdbId: Int
    let initialDetail: MediaDetails?

    @State private var detail: MediaDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var alertItem: AlertItem?
    @State private var isRequesting = false
    @State private var hasRequested = false
    @Environment(\.openURL) private var openURL
    @State private var requestIs4k: Bool = false
    @State private var selectedSeasons: Set<Int> = []

    private var api: OverseerrAPI? {
        guard settings.isConfigured, let baseURL = settings.baseURL else { return nil }
        return OverseerrAPI(configuration: .init(baseURL: baseURL, apiKey: settings.apiKey))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                overview
                if let providers = detail?.watchProviders, !providers.isEmpty {
                    watchProvidersSection(providers: providers)
                }
                if let cast = detail?.credits?.cast, !cast.isEmpty {
                    castSection(cast: cast)
                }
                if let trailer = detail?.relatedVideos?.first {
                    trailerSection(trailer: trailer)
                }
                actionSection
            }
            .padding()
        }
        .navigationTitle(detail?.displayTitle ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIfNeeded() }
        .alert(item: $alertItem) { item in
            Alert(title: Text(item.message))
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            PosterView(imageURL: detail?.posterURL(width: 500))
                .frame(width: 120, height: 180)

            VStack(alignment: .leading, spacing: 8) {
                    Text(detail?.displayTitle ?? "")
                        .font(.title2)
                        .bold()
                        .lineLimit(2)
                if let year = detail?.displayYear {
                    Text(year)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    if let vote = detail?.voteAverage {
                        Label(String(format: "%.1f", vote), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.subheadline)
                    }
                    if let runtime = detail?.runtime, mediaType == .movie {
                        Text(formattedRuntime(minutes: runtime))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if mediaType == .tv, let seasons = detail?.numberOfSeasons {
                        Text("\(seasons) season\(seasons == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if let status = detail?.mediaInfo?.status {
                    Text("Status: \(status.label)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let deepLink = detail?.mediaInfo?.serviceUrl, let url = URL(string: deepLink) {
                    Button(action: { openURL(url) }) {
                        Label("Open in Overseerr", systemImage: "arrow.up.right.square")
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
            if let overview = detail?.overview, !overview.isEmpty {
                Text(overview)
                    .foregroundStyle(.secondary)
            } else {
                Text("No description available.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView("Loading…")
            }
            if mediaType == .tv {
                seasonPicker
            }
            Toggle("Request 4K", isOn: $requestIs4k)
                .toggleStyle(.switch)
                .padding(.vertical, 4)
            Button(action: submitRequest) {
                HStack {
                    Spacer()
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(hasRequested ? "Requested" : "Request")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(hasRequested ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isRequesting || hasRequested || !settings.isConfigured)
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func loadIfNeeded() async {
        if detail != nil { return }
        detail = initialDetail
        if let status = initialDetail?.mediaInfo?.status, status != .unknown {
            hasRequested = true
        }
        guard let api else { return }
        isLoading = true
        do {
            detail = try await api.mediaDetails(type: mediaType, tmdbId: tmdbId)
            if let status = detail?.mediaInfo?.status, status != .unknown {
                hasRequested = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func submitRequest() {
        guard let api else {
            alertItem = AlertItem(message: "Connect to Overseerr first.")
            return
        }
        isRequesting = true
        Task {
            do {
                let seasonsSelection: SeasonSelection?
                if mediaType == .tv {
                    seasonsSelection = selectedSeasons.isEmpty ? .all : .seasons(Array(selectedSeasons).sorted())
                } else {
                    seasonsSelection = nil
                }
                let body = MediaRequestBody(
                    mediaType: mediaType,
                    mediaId: tmdbId,
                    tvdbId: detail?.mediaInfo?.tvdbId,
                    seasons: seasonsSelection,
                    is4k: requestIs4k,
                    serverId: nil,
                    profileId: nil,
                    rootFolder: nil,
                    languageProfileId: nil,
                    userId: nil,
                    tags: nil
                )
                let _ = try await api.requestMedia(body: body)
                hasRequested = true
                alertItem = AlertItem(message: "Request submitted")
            } catch {
                alertItem = AlertItem(message: error.localizedDescription)
            }
            isRequesting = false
        }
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

private func formattedRuntime(minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 {
        return "\(hours)h \(mins)m"
    }
    return "\(mins)m"
}

private func watchProvidersSection(providers: [WatchProviderRegion]) -> some View {
    let first = providers.first
    let options = first?.flatrate ?? first?.rent ?? first?.buy ?? []
    return VStack(alignment: .leading, spacing: 8) {
        Text("Watch Providers")
            .font(.headline)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.id) { provider in
                    Text(provider.providerName ?? "Provider")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private func castSection(cast: [CastMember]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Cast")
            .font(.headline)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(cast.prefix(10)) { member in
                    VStack(alignment: .leading, spacing: 6) {
                        PosterView(imageURL: member.avatarURL)
                            .frame(width: 80, height: 120)
                        Text(member.name)
                            .font(.caption)
                            .lineLimit(1)
                        if let role = member.character {
                            Text(role)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 90, alignment: .leading)
                }
            }
        }
    }
}

private func trailerSection(trailer: Video) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Trailer")
            .font(.headline)
        if let url = trailer.url ?? URL(string: "https://www.youtube.com/watch?v=\(trailer.key)") {
            Link(destination: url) {
                Label(trailer.name, systemImage: "play.rectangle.fill")
            }
        } else {
            Text("No trailer available.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

private extension MediaDetailView {
    var seasonPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seasons")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: {
                        selectedSeasons.removeAll()
                    }) {
                        Text("All")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedSeasons.isEmpty ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if let count = detail?.numberOfSeasons {
                        ForEach(1...count, id: \.self) { season in
                            let isSelected = selectedSeasons.contains(season)
                            Button(action: {
                                if isSelected {
                                    selectedSeasons.remove(season)
                                } else {
                                    selectedSeasons.insert(season)
                                }
                            }) {
                                Text("S\(season)")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
}
