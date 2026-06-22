//
//  MockURLProtocol.swift
//  RandomUserTests
//

import Foundation

/// Intercepts `URLSession` traffic so the live `RandomUserAPIClient` can be tested
/// without hitting the network. Install via `URLSessionConfiguration.protocolClasses`.
nonisolated final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Builds the response for a given request. Set per test.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    /// The last request seen, for URL/query assertions.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let handler = Self.requestHandler else {
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
}
