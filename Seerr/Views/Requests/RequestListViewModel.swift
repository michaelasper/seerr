import Foundation

@MainActor
final class RequestListViewModel: ObservableObject {
    @Published private(set) var requests: [MediaRequest] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private var api: OverseerrAPI?
    @Published private var detailsCache: [MediaKey: MediaDetails] = [:]

    func reload(using settings: AppSettings) async {
        guard let baseURL = settings.baseURL, settings.isConfigured else {
            requests = []
            api = nil
            errorMessage = "Add your Overseerr base URL and API key to get started."
            isLoading = false
            return
        }

        api = OverseerrAPI(configuration: .init(baseURL: baseURL, apiKey: settings.apiKey))
        await loadRequests()
    }

    func detail(for request: MediaRequest) -> MediaDetails? {
        guard let key = mediaKey(for: request) else { return nil }
        return detailsCache[key]
    }

    func fetchDetailIfNeeded(for request: MediaRequest) async {
        guard let api, let key = mediaKey(for: request), detailsCache[key] == nil else { return }

        do {
            let detail = try await api.mediaDetails(type: key.type, tmdbId: key.id)
            detailsCache[key] = detail
        } catch {
            // Ignore detail fetch errors so we still render the base request row.
        }
    }

    // MARK: - Private

    private func loadRequests() async {
        guard let api else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await api.listRequests(take: 25, filter: .all, sort: .modified)
            requests = page.results
        } catch {
            errorMessage = error.localizedDescription
            requests = []
        }
        isLoading = false
    }

    private func mediaKey(for request: MediaRequest) -> MediaKey? {
        guard let tmdbId = request.media?.tmdbId else { return nil }
        let mediaType = request.media?.mediaType ?? request.type
        return MediaKey(id: tmdbId, type: mediaType)
    }

    private struct MediaKey: Hashable {
        let id: Int
        let type: MediaType
    }
}
