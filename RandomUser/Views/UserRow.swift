//
//  UserRow.swift
//  RandomUser
//

import SwiftUI

/// List cell: thumbnail + the fields the brief asks for (name, email, phone).
struct UserRow: View {
    let user: UserModel

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(user: user, url: user.thumbnailURL, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(user.phone)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    List {
        UserRow(user: .sample())
    }
}
#endif
