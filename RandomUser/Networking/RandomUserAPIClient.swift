//
//  RandomUserAPIClient.swift
//  RandomUser
//

import Foundation

/// Live `APIClient` backed by `URLSession`. HTTPS only — plain `http` would be blocked by
/// App Transport Security, and no ATS exceptions are added.
nonisolated struct RandomUserAPIClient: APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    @concurrent func fetchUsers(seed: String, page: Int, results: Int) async throws -> [UserDTO] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "randomuser.me"
        components.path = "/api/"
        components.queryItems = [
            URLQueryItem(name: "seed", value: seed),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "results", value: String(results)),
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder.randomUser().decode(UsersResponseDTO.self, from: data).results
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }
}
