import Foundation

enum MediaType: String, Codable, CaseIterable, Hashable {
    case movie
    case tv
}

enum SeasonSelection: Codable, Hashable {
    case all
    case seasons([Int])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self), string == "all" {
            self = .all
        } else if let numbers = try? container.decode([Int].self) {
            self = .seasons(numbers)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid season selection")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .all:
            try container.encode("all")
        case .seasons(let numbers):
            try container.encode(numbers)
        }
    }
}

struct MediaRequestBody: Codable {
    let mediaType: MediaType
    let mediaId: Int
    let tvdbId: Int?
    let seasons: SeasonSelection?
    let is4k: Bool
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
    let languageProfileId: Int?
    let userId: Int?
    let tags: [Int]?
}

enum MediaRequestStatus: Int, Codable, CaseIterable {
    case pending = 1
    case approved
    case declined
    case failed
    case completed

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .failed: return "Failed"
        case .completed: return "Completed"
        }
    }
}

enum MediaStatus: Int, Codable {
    case unknown = 1
    case pending
    case processing
    case partiallyAvailable
    case available
    case deleted

    var label: String {
        switch self {
        case .unknown: return "Unknown"
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .partiallyAvailable: return "Partially Available"
        case .available: return "Available"
        case .deleted: return "Deleted"
        }
    }
}

struct Video: Decodable, Hashable {
    let url: URL?
    let site: String?
    let key: String
    let name: String
    let size: Int?
    let type: String?
}

struct PageInfo: Codable {
    let pages: Int
    let page: Int
    let results: Int
    let pageSize: Int
}

struct RequestPage: Codable {
    let pageInfo: PageInfo
    let results: [MediaRequest]
}

struct UserSummary: Codable, Identifiable, Hashable {
    let id: Int
    let email: String?
    let username: String?
    let displayName: String?
    let avatar: String?

    var name: String {
        displayName ?? username ?? email ?? "User \(id)"
    }
}

struct CurrentUser: Decodable, Identifiable, Hashable {
    let id: Int
    let email: String?
    let username: String?
    let displayName: String?
    let avatar: String?
    let permissions: [String]?
    let permissionsValue: Int?
    let roles: [String]?

    var name: String {
        displayName ?? username ?? email ?? "User \(id)"
    }

    var permissionLabels: [String] {
        if let permissions, !permissions.isEmpty {
            return permissions
        }
        if let permissionsValue {
            return ["Permission bits: \(permissionsValue)"]
        }
        return []
    }
}

struct SeasonRequest: Codable, Identifiable, Hashable {
    var id: Int { seasonNumber }
    let seasonNumber: Int
    let status: MediaRequestStatus?
}

struct RequestedMedia: Codable, Hashable {
    let id: Int?
    let mediaType: MediaType?
    let tmdbId: Int?
    let tvdbId: Int?
    let imdbId: String?
    let status: MediaStatus?
    let status4k: MediaStatus?
    let serviceUrl: String?
    let serviceUrl4k: String?
}

struct MediaRequest: Codable, Identifiable, Hashable {
    let id: Int
    let status: MediaRequestStatus
    let type: MediaType
    let media: RequestedMedia?
    let requestedBy: UserSummary?
    let modifiedBy: UserSummary?
    let is4k: Bool?
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
    let createdAt: Date?
    let updatedAt: Date?
    let seasons: [SeasonRequest]?
}

struct MediaDetails: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaInfo: RequestedMedia?
    let runtime: Int?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let credits: Credits?
    let relatedVideos: [Video]?
    let watchProviders: [WatchProviderRegion]?

    var displayTitle: String {
        title ?? name ?? "Unknown Title"
    }

    var displayYear: String? {
        let source = releaseDate ?? firstAirDate
        return source?.split(separator: "-").first.map(String.init)
    }

    func posterURL(width: Int = 342) -> URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w\(width)\(posterPath)")
    }

    init(id: Int, title: String?, name: String?, overview: String?, posterPath: String?, backdropPath: String?, releaseDate: String?, firstAirDate: String?, voteAverage: Double?, mediaInfo: RequestedMedia?, runtime: Int? = nil, numberOfSeasons: Int? = nil, numberOfEpisodes: Int? = nil, credits: Credits? = nil, relatedVideos: [Video]? = nil, watchProviders: [WatchProviderRegion]? = nil) {
        self.id = id
        self.title = title
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.firstAirDate = firstAirDate
        self.voteAverage = voteAverage
        self.mediaInfo = mediaInfo
        self.runtime = runtime
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.credits = credits
        self.relatedVideos = relatedVideos
        self.watchProviders = watchProviders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage)
        mediaInfo = try container.decodeIfPresent(RequestedMedia.self, forKey: .mediaInfo)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        numberOfEpisodes = try container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes)
        credits = try container.decodeIfPresent(Credits.self, forKey: .credits)
        relatedVideos = try container.decodeIfPresent([Video].self, forKey: .relatedVideos)
        watchProviders = try container.decodeIfPresent([WatchProviderRegion].self, forKey: .watchProviders)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case posterPath
        case backdropPath
        case releaseDate
        case firstAirDate
        case voteAverage
        case mediaInfo
        case runtime
        case numberOfSeasons
        case numberOfEpisodes
        case credits
        case relatedVideos
        case watchProviders
    }
}

struct SearchPage<T: Decodable>: Decodable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [T]
}

struct SearchResult: Decodable, Identifiable, Hashable {
    let id: Int
    let mediaType: MediaType?
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaInfo: RequestedMedia?

    var displayTitle: String {
        title ?? name ?? "Unknown Title"
    }

    var displayYear: String? {
        let source = releaseDate ?? firstAirDate
        return source?.split(separator: "-").first.map(String.init)
    }

    func posterURL(width: Int = 342) -> URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w\(width)\(posterPath)")
    }

    init(id: Int, mediaType: MediaType?, title: String?, name: String?, overview: String?, posterPath: String?, backdropPath: String?, releaseDate: String?, firstAirDate: String?, voteAverage: Double?, mediaInfo: RequestedMedia?) {
        self.id = id
        self.mediaType = mediaType
        self.title = title
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.firstAirDate = firstAirDate
        self.voteAverage = voteAverage
        self.mediaInfo = mediaInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        if let rawType = try? container.decode(String.self, forKey: .mediaType), let type = MediaType(rawValue: rawType) {
            mediaType = type
        } else {
            mediaType = nil
        }
        title = try container.decodeIfPresent(String.self, forKey: .title)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage)
        mediaInfo = try container.decodeIfPresent(RequestedMedia.self, forKey: .mediaInfo)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mediaType
        case title
        case name
        case overview
        case posterPath
        case backdropPath
        case releaseDate
        case firstAirDate
        case voteAverage
        case mediaInfo
    }
}

struct Credits: Decodable, Hashable {
    let cast: [CastMember]?
    let crew: [CrewMember]?
}

struct CastMember: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    var avatarURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct CrewMember: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let job: String?
    let profilePath: String?
}

struct WatchProviderOption: Decodable, Identifiable, Hashable {
    let providerId: Int?
    let providerName: String?
    let logoPath: String?
    let displayPriority: Int?

    var id: Int { providerId ?? UUID().hashValue }
}

struct WatchProviderRegion: Decodable, Hashable {
    let countryCode: String
    let flatrate: [WatchProviderOption]?
    let rent: [WatchProviderOption]?
    let buy: [WatchProviderOption]?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: ProviderGroup].self), let first = dict.first {
            countryCode = first.key
            flatrate = first.value.flatrate
            rent = first.value.rent
            buy = first.value.buy
        } else {
            countryCode = "US"
            let group = try container.decode(ProviderGroup.self)
            flatrate = group.flatrate
            rent = group.rent
            buy = group.buy
        }
    }

    private struct ProviderGroup: Decodable, Hashable {
        let flatrate: [WatchProviderOption]?
        let rent: [WatchProviderOption]?
        let buy: [WatchProviderOption]?
    }
}
