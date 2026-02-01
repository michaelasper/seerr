import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published private(set) var trending: [SearchResult] = []
    @Published private(set) var movies: [SearchResult] = []
    @Published private(set) var tv: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedGenre: String?
    @Published var selectedYear: String?
    @Published var sortOption: SortOption = .popularity
    @Published var trendingPeriod: TrendingPeriod = .week

    private var api: OverseerrAPI?
    private let availableSorts: [SortOption] = SortOption.allCases

    func load(using settings: AppSettings) async {
        guard let baseURL = settings.baseURL, settings.isConfigured else {
            trending = []
            movies = []
            tv = []
            errorMessage = "Configure Overseerr to browse."
            return
        }

        api = OverseerrAPI(configuration: .init(baseURL: baseURL, apiKey: settings.apiKey))
        await fetchContent()
    }

    // MARK: - Private

    private func fetchContent() async {
        guard let api else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let trendingTask = api.trending()
            async let moviesTask = api.discoverMoviesFiltered(
                page: 1,
                genre: selectedGenre,
                year: selectedYear,
                sort: sortOption.rawValue
            )
            async let tvTask = api.discoverTvFiltered(
                page: 1,
                genre: selectedGenre,
                year: selectedYear,
                sort: sortOption.rawValue
            )

            let (trendingPage, moviePage, tvPage) = try await (trendingTask, moviesTask, tvTask)
            trending = trendingPage.results.filter { $0.mediaType == .movie || $0.mediaType == .tv }
            movies = moviePage.results
            tv = tvPage.results
        } catch {
            errorMessage = error.localizedDescription
            trending = []
            movies = []
            tv = []
        }
        isLoading = false
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case popularity = "popularity.desc"
        case rating = "vote_average.desc"
        case newest = "primary_release_date.desc"

        var id: String { rawValue }
        var label: String {
            switch self {
            case .popularity: return "Popularity"
            case .rating: return "Rating"
            case .newest: return "Newest"
            }
        }
    }

    enum TrendingPeriod: String, CaseIterable, Identifiable {
        case day
        case week

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }
}
