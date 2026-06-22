//
//  APIClientTests.swift
//  RandomUserTests
//

import Foundation
import Testing
@testable import RandomUser

/// Serialized: the tests share `MockURLProtocol`'s static state, so they must not
/// run in parallel.
@Suite(.serialized)
struct APIClientTests {

    private func makeClient() -> RandomUserAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return RandomUserAPIClient(session: URLSession(configuration: config))
    }

    @Test("Builds an HTTPS URL with seed/page/results and decodes the results")
    func decodesAndBuildsURL() async throws {
        MockURLProtocol.requestHandler = { request in
            let http = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (http, Data(Self.sampleJSON.utf8))
        }

        let users = try await makeClient().fetchUsers(seed: "abc", page: 2, results: 40)

        #expect(users.count == 1)
        #expect(users.first?.login.uuid == "f5f515be-0509-492d-993e-6c582a520310")

        let url = try #require(MockURLProtocol.lastRequest?.url)
        #expect(url.scheme == "https")
        #expect(url.host == "randomuser.me")
        let query = try #require(url.query)
        #expect(query.contains("seed=abc"))
        #expect(query.contains("page=2"))
        #expect(query.contains("results=40"))
    }

    @Test("Maps a non-2xx response to APIError.httpStatus")
    func throwsOnHTTPError() async throws {
        MockURLProtocol.requestHandler = { request in
            let http = HTTPURLResponse(
                url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (http, Data())
        }

        await #expect(throws: APIError.self) {
            try await makeClient().fetchUsers(seed: "x", page: 1, results: 40)
        }
    }
}

private extension APIClientTests {
    static let sampleJSON = """
    {
      "results": [
        {
          "gender": "female",
          "name": { "title": "Ms", "first": "Zlata", "last": "Kuzmanović" },
          "location": {
            "street": { "number": 1108, "name": "Janka Đurđevića" },
            "city": "Štrpce", "state": "Toplica"
          },
          "email": "zlata.kuzmanovic@example.com",
          "login": { "uuid": "f5f515be-0509-492d-993e-6c582a520310" },
          "registered": { "date": "2012-06-12T20:59:59.976Z", "age": 14 },
          "phone": "023-1020-037",
          "picture": {
            "large": "https://randomuser.me/api/portraits/women/12.jpg",
            "thumbnail": "https://randomuser.me/api/portraits/thumb/women/12.jpg"
          }
        }
      ],
      "info": { "seed": "abc", "results": 1, "page": 2, "version": "1.4" }
    }
    """
}
