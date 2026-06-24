//
//  PaginationState.swift
//  RandomUser
//

import Foundation
import SwiftData

/// Persisted pagination cursor. A single record holds the session's `seed` and the
/// next page to fetch, so pagination *resumes* across launches instead of restarting
/// at page 1 — which would re-fetch already-stored pages (all duplicates) and stall
/// the infinite scroll, since the list only grows when new users arrive.
@Model
final class PaginationState {
    var seed: String
    var nextPage: Int

    init(seed: String, nextPage: Int = 1) {
        self.seed = seed
        self.nextPage = nextPage
    }
}
