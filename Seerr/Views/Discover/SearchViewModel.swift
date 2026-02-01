import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var results: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    private var api: OverseerrAPI?
    private var currentQuery: String = ""

    func updateConfiguration(settings: AppSettings) {
        guard let baseURL = settings.baseURL, settings.isConfigured else {
            api = nil
            results = []
            return
        }
        api = OverseerrAPI(configuration: .init(baseURL: baseURL, apiKey: settings.apiKey))
    }

    func search(query: String) async {
        guard let api else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        currentQuery = trimmed
        isSearching = true
        errorMessage = nil

        do {
            let page = try await api.search(query: trimmed)
            if trimmed == currentQuery {
                results = page.results.filter { $0.mediaType == .movie || $0.mediaType == .tv }
            }
        } catch {
            if trimmed == currentQuery {
                errorMessage = error.localizedDescription
                results = []
            }
        }
        isSearching = false
    }
}
