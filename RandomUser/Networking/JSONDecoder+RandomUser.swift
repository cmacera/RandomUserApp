//
//  JSONDecoder+RandomUser.swift
//  RandomUser
//

import Foundation

extension JSONDecoder {
    /// Decoder configured for the randomuser.me API.
    ///
    /// The dates come as ISO8601 *with fractional seconds* (e.g. `2012-06-12T20:59:59.976Z`),
    /// which the built-in `.iso8601` strategy does NOT parse — its formatter omits
    /// `.withFractionalSeconds`. A custom strategy tries the fractional formatter
    /// first and falls back to the plain one, so both shapes decode.
    nonisolated static func randomUser() -> JSONDecoder {
        let decoder = JSONDecoder()
        let parser = ISO8601Parser()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = parser.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(string)"
            )
        }

        return decoder
    }
}

/// Parses ISO8601 strings with or without fractional seconds. `@unchecked Sendable`
/// is sound here: the formatters are configured once at init and only ever read
/// (`date(from:)` is thread-safe), so the captured instance is safe to share across
/// the `@Sendable` decoding closure.
private nonisolated struct ISO8601Parser: @unchecked Sendable {
    private let withFractional: ISO8601DateFormatter
    private let withoutFractional: ISO8601DateFormatter

    init() {
        withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
    }

    func date(from string: String) -> Date? {
        withFractional.date(from: string) ?? withoutFractional.date(from: string)
    }
}
