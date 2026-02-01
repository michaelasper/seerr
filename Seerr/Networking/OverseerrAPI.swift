import Foundation

enum OverseerrAPIError: LocalizedError {
    case badURL
    case badResponse(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .badResponse(let code):
            return "Server responded with status code \(code)"
        case .decodingFailed:
            return "Failed to decode Overseerr response"
        }
    }
}

struct OverseerrAPI {
    static var sessionFactory: () -> URLSession = { .shared }

    struct Configuration {
        let baseURL: URL
        let apiKey: String
    }

    enum RequestFilter: String, CaseIterable {
        case all
        case pending
        case approved
        case declined
        case failed
        case completed
        case processing
        case unavailable
        case available
        case deleted

        var queryValue: String? {
            switch self {
            case .all:
                return nil
            default:
                return rawValue
            }
        }
    }

    enum RequestSort: String {
        case recent
        case modified

        var queryValue: String {
            switch self {
            case .recent:
                return "id"
            case .modified:
                return "modified"
            }
        }
    }

    var configuration: Configuration
    private var session: URLSession { Self.sessionFactory() }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = OverseerrAPI.iso8601WithFractional.date(from: string) {
                return date
            }
            if let fallback = OverseerrAPI.iso8601.date(from: string) {
                return fallback
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }

    func listRequests(take: Int = 25, filter: RequestFilter = .all, sort: RequestSort = .recent) async throws -> RequestPage {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "sort", value: sort.queryValue)
        ]

        if let filterValue = filter.queryValue {
            query.append(URLQueryItem(name: "filter", value: filterValue))
        }

        return try await perform(RequestPage.self, path: "request", queryItems: query)
    }

    func mediaDetails(type: MediaType, tmdbId: Int) async throws -> MediaDetails {
        let path: String
        switch type {
        case .movie:
            path = "movie/\(tmdbId)"
        case .tv:
            path = "tv/\(tmdbId)"
        }

        return try await perform(MediaDetails.self, path: path)
    }

    func search(query: String) async throws -> SearchPage<SearchResult> {
        let items = [URLQueryItem(name: "query", value: query)]
        return try await perform(SearchPage<SearchResult>.self, path: "search", queryItems: items)
    }

    func trending() async throws -> SearchPage<SearchResult> {
        try await perform(SearchPage<SearchResult>.self, path: "discover/trending")
    }

    func discoverMovies(page: Int = 1) async throws -> SearchPage<SearchResult> {
        let items = [URLQueryItem(name: "page", value: String(page))]
        return try await perform(SearchPage<SearchResult>.self, path: "discover/movies", queryItems: items)
    }

    func discoverTv(page: Int = 1) async throws -> SearchPage<SearchResult> {
        let items = [URLQueryItem(name: "page", value: String(page))]
        return try await perform(SearchPage<SearchResult>.self, path: "discover/tv", queryItems: items)
    }
    
    func discoverMoviesFiltered(page: Int = 1, genre: String? = nil, year: String? = nil, sort: String? = nil) async throws -> SearchPage<SearchResult> {
        var items = [URLQueryItem(name: "page", value: String(page))]
        if let genre { items.append(URLQueryItem(name: "genre", value: genre)) }
        if let year { items.append(URLQueryItem(name: "primaryReleaseDateGte", value: "\(year)-01-01")) }
        if let sort { items.append(URLQueryItem(name: "sortBy", value: sort)) }
        return try await perform(SearchPage<SearchResult>.self, path: "discover/movies", queryItems: items)
    }
    
    func discoverTvFiltered(page: Int = 1, genre: String? = nil, year: String? = nil, sort: String? = nil) async throws -> SearchPage<SearchResult> {
        var items = [URLQueryItem(name: "page", value: String(page))]
        if let genre { items.append(URLQueryItem(name: "genre", value: genre)) }
        if let year { items.append(URLQueryItem(name: "firstAirDateGte", value: "\(year)-01-01")) }
        if let sort { items.append(URLQueryItem(name: "sortBy", value: sort)) }
        return try await perform(SearchPage<SearchResult>.self, path: "discover/tv", queryItems: items)
    }

    func requestMedia(body: MediaRequestBody) async throws -> MediaRequest {
        let data = try JSONEncoder().encode(body)
        return try await perform(MediaRequest.self, path: "request", method: "POST", body: data)
    }

    func fetchCurrentUser() async throws -> CurrentUser {
        try await perform(CurrentUser.self, path: "user/me")
    }

    // MARK: - Helpers

    private func perform<T: Decodable>(_ type: T.Type, path: String, method: String = "GET", queryItems: [URLQueryItem] = [], body: Data? = nil) async throws -> T {
        let request = try makeRequest(path: path, method: method, queryItems: queryItems, body: body)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OverseerrAPIError.badResponse(-1)
        }

        guard 200..<300 ~= http.statusCode else {
            throw OverseerrAPIError.badResponse(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw OverseerrAPIError.decodingFailed
        }
    }

    private func makeRequest(path: String, method: String = "GET", queryItems: [URLQueryItem] = [], body: Data? = nil) throws -> URLRequest {
        let base = configuration.baseURL.appendingPathComponent("api/v1")
        guard var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw OverseerrAPIError.badURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw OverseerrAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue(configuration.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
