import Foundation

#if DEBUG
final class MockServer {
    static func enableIfNeeded() {
        let env = ProcessInfo.processInfo.environment
        let hasRealCreds = (env["USE_REAL_OVERSEERR"] == "1") || (env["OVERSEERR_BASE_URL"]?.isEmpty == false && env["OVERSEERR_API_KEY"]?.isEmpty == false)
        guard env["UI_TEST_MODE"] == "1" else { return }
        guard !hasRealCreds else { return }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        OverseerrAPI.sessionFactory = { URLSession(configuration: configuration) }
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler ?? MockURLProtocol.defaultHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static var defaultHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? = { request in
        guard let url = request.url else { throw URLError(.badURL) }
        let path = url.path

        switch true {
        case path == "/api/v1/request" && request.httpMethod == "GET":
            return try respond(json: MockResponses.requestList, url: url)
        case path == "/api/v1/request" && request.httpMethod == "POST":
            return try respond(json: MockResponses.requestCreated, url: url, statusCode: 201)
        case path == "/api/v1/user/me":
            return try respond(json: MockResponses.currentUser, url: url)
        case path.contains("/api/v1/movie/"):
            return try respond(json: MockResponses.movieDetails, url: url)
        case path.contains("/api/v1/tv/"):
            return try respond(json: MockResponses.tvDetails, url: url)
        case path.contains("/api/v1/discover"):
            return try respond(json: MockResponses.trending, url: url)
        case path.contains("/api/v1/search"):
            return try respond(json: MockResponses.trending, url: url)
        default:
            throw URLError(.resourceUnavailable)
        }
    }

    private static func respond(json: String, url: URL, statusCode: Int = 200) throws -> (HTTPURLResponse, Data) {
        guard let data = json.data(using: .utf8) else { throw URLError(.cannotDecodeContentData) }
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"]) else {
            throw URLError(.badServerResponse)
        }
        return (response, data)
    }
}

private enum MockResponses {
    static let currentUser = """
    {
      "id": 1,
      "email": "admin@example.com",
      "username": "admin",
      "displayName": "Admin",
      "avatar": null,
      "permissions": ["ADMIN", "MANAGE_REQUESTS", "REQUEST"],
      "roles": ["admin"]
    }
    """

    static let requestList = """
    {
      "pageInfo": {
        "pages": 1,
        "page": 1,
        "results": 2,
        "pageSize": 25
      },
      "results": [
        {
          "id": 42,
          "status": 2,
          "type": "movie",
          "media": {
            "id": 101,
            "mediaType": "movie",
            "tmdbId": 603692,
            "status": 1,
            "status4k": 1
          },
          "requestedBy": {
            "id": 1,
            "email": "admin@example.com",
            "username": "admin",
            "displayName": "Admin"
          },
          "is4k": true,
          "createdAt": "2023-11-27T10:00:00.000Z",
          "updatedAt": "2023-11-27T10:10:00.000Z",
          "seasons": []
        },
        {
          "id": 43,
          "status": 1,
          "type": "tv",
          "media": {
            "id": 102,
            "mediaType": "tv",
            "tmdbId": 2316,
            "status": 2,
            "status4k": 1
          },
          "requestedBy": {
            "id": 2,
            "email": "user@example.com",
            "username": "steve",
            "displayName": "Steve"
          },
          "is4k": false,
          "createdAt": "2023-11-26T15:00:00.000Z",
          "updatedAt": "2023-11-26T15:10:00.000Z",
          "seasons": [
            { "seasonNumber": 1, "status": 1 },
            { "seasonNumber": 2, "status": 1 }
          ]
        }
      ]
    }
    """

    static let movieDetails = """
    {
      "id": 603692,
      "title": "John Wick: Chapter 4",
      "overview": "With the price on his head ever increasing, legendary hit man John Wick takes his fight against the High Table global…",
      "posterPath": "/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg",
      "releaseDate": "2023-03-22",
      "voteAverage": 7.7,
      "mediaInfo": {
        "id": 101,
        "mediaType": "movie",
        "tmdbId": 603692,
        "status": 1,
        "status4k": 1
      }
    }
    """

    static let tvDetails = """
    {
      "id": 2316,
      "name": "The Office",
      "overview": "A mockumentary on a group of typical office workers, where the workday consists of ego clashes, inappropriate behavior, and tedium.",
      "posterPath": "/office.jpg",
      "firstAirDate": "2005-03-24",
      "voteAverage": 8.5,
      "mediaInfo": {
        "id": 102,
        "mediaType": "tv",
        "tmdbId": 2316,
        "status": 2,
        "status4k": 1
      }
    }
    """

    static let trending = """
    {
      "page": 1,
      "totalPages": 1,
      "totalResults": 2,
      "results": [
        {
          "id": 603692,
          "mediaType": "movie",
          "title": "John Wick: Chapter 4",
          "overview": "With the price on his head ever increasing, legendary hit man John Wick takes his fight against the High Table global…",
          "posterPath": "/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg",
          "releaseDate": "2023-03-22",
          "voteAverage": 7.7
        },
        {
          "id": 2316,
          "mediaType": "tv",
          "name": "The Office",
          "overview": "A mockumentary on a group of typical office workers, where the workday consists of ego clashes, inappropriate behavior, and tedium.",
          "posterPath": "/office.jpg",
          "firstAirDate": "2005-03-24",
          "voteAverage": 8.5
        }
      ]
    }
    """

    static let requestCreated = """
    {
      "id": 99,
      "status": 2,
      "type": "movie",
      "media": {
        "id": 101,
        "mediaType": "movie",
        "tmdbId": 603692,
        "status": 1,
        "status4k": 1
      },
      "requestedBy": {
        "id": 1,
        "email": "admin@example.com",
        "username": "admin",
        "displayName": "Admin"
      },
      "is4k": false,
      "createdAt": "2023-11-27T10:00:00.000Z",
      "updatedAt": "2023-11-27T10:10:00.000Z",
      "seasons": []
    }
    """
}
#endif
