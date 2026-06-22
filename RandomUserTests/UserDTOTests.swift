//
//  UserDTOTests.swift
//  RandomUserTests
//

import Foundation
import Testing
@testable import RandomUser

struct UserDTOTests {

    @Test("Decodes the live API shape, ignoring fields we don't model")
    func decodesLiveShape() throws {
        let response = try JSONDecoder.randomUser()
            .decode(UsersResponseDTO.self, from: Data(Self.sampleJSON.utf8))

        #expect(response.results.count == 1)
        let dto = try #require(response.results.first)

        #expect(dto.login.uuid == "f5f515be-0509-492d-993e-6c582a520310")
        #expect(dto.name.first == "Zlata")
        #expect(dto.name.last == "Kuzmanović")
        #expect(dto.email == "zlata.kuzmanovic@example.com")
        #expect(dto.gender == "female")
        #expect(dto.phone == "023-1020-037")
        #expect(dto.location.street.number == 1108)
        #expect(dto.location.city == "Štrpce")
        #expect(dto.location.state == "Toplica")
        #expect(dto.picture.thumbnail.contains("thumb"))
    }

    @Test("Maps DTO to model: composes street, picks list/detail URLs, injects sortOrder")
    @MainActor
    func mapsToModel() throws {
        let dto = try JSONDecoder.randomUser()
            .decode(UsersResponseDTO.self, from: Data(Self.sampleJSON.utf8))
            .results[0]

        let model = dto.toModel(sortOrder: 7)

        #expect(model.uuid == "f5f515be-0509-492d-993e-6c582a520310")
        #expect(model.sortOrder == 7)
        #expect(model.fullName == "Zlata Kuzmanović")
        // Composed from { number: 1108, name: "Janka Đurđevića " } and trimmed.
        #expect(model.street == "1108 Janka Đurđevića")
        #expect(model.thumbnailURL == "https://randomuser.me/api/portraits/thumb/women/12.jpg")
        #expect(model.pictureURL == "https://randomuser.me/api/portraits/women/12.jpg")
    }

    @Test("Parses ISO8601 dates that carry fractional seconds")
    func parsesFractionalSecondsDate() throws {
        let dto = try JSONDecoder.randomUser()
            .decode(UsersResponseDTO.self, from: Data(Self.sampleJSON.utf8))
            .results[0]

        // registered.date == "2012-06-12T20:59:59.976Z"
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let c = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: dto.registered.date
        )
        #expect(c.year == 2012)
        #expect(c.month == 6)
        #expect(c.day == 12)
        #expect(c.hour == 20)
        #expect(c.minute == 59)
        #expect(c.second == 59)
    }
}

private extension UserDTOTests {
    /// One result in the live (v1.4) shape, deliberately including fields the DTO
    /// does NOT decode — `login.password`, `id.value`, Int `postcode`, `dob`, `cell`,
    /// `nat` — to prove they're ignored rather than causing a decode failure.
    static let sampleJSON = """
    {
      "results": [
        {
          "gender": "female",
          "name": { "title": "Ms", "first": "Zlata", "last": "Kuzmanović" },
          "location": {
            "street": { "number": 1108, "name": "Janka Đurđevića " },
            "city": "Štrpce",
            "state": "Toplica",
            "country": "Serbia",
            "postcode": 14658,
            "coordinates": { "latitude": "63.5285", "longitude": "99.5770" },
            "timezone": { "offset": "-3:00", "description": "Brazil" }
          },
          "email": "zlata.kuzmanovic@example.com",
          "login": {
            "uuid": "f5f515be-0509-492d-993e-6c582a520310",
            "username": "whitegorilla792",
            "password": "clevelan"
          },
          "dob": { "date": "1965-05-29T11:03:43.330Z", "age": 61 },
          "registered": { "date": "2012-06-12T20:59:59.976Z", "age": 14 },
          "phone": "023-1020-037",
          "cell": "065-5172-993",
          "id": { "name": "SID", "value": null },
          "picture": {
            "large": "https://randomuser.me/api/portraits/women/12.jpg",
            "medium": "https://randomuser.me/api/portraits/med/women/12.jpg",
            "thumbnail": "https://randomuser.me/api/portraits/thumb/women/12.jpg"
          },
          "nat": "RS"
        }
      ],
      "info": { "seed": "2dcc676d1aae790f", "results": 1, "page": 1, "version": "1.4" }
    }
    """
}
