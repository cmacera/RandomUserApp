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
    /// `.withFractionalSeconds`. We use a custom strategy that tries the fractional
    /// formatter first and falls back to the plain one, so both shapes decode.
    static func randomUser() -> JSONDecoder {
        let decoder = JSONDecoder()

        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFractional.date(from: string) ?? withoutFractional.date(from: string) {
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
