//
//  UserDetailView.swift
//  RandomUser
//

import SwiftUI

/// Detail screen with the fields the brief asks for: picture, name, gender, location
/// (street/city/state), registered date, email.
struct UserDetailView: View {
    let user: UserModel

    var body: some View {
        List {
            Section {
                AvatarView(user: user, url: user.pictureURL, size: 200)
                    .overlay { Circle().stroke(.tint, lineWidth: 3) }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            Section {
                row("Name", user.fullName)
                row("Gender", user.gender.capitalized)
                row("Email", user.email)
            }

            Section {
                row("Street", user.street)
                row("City", user.city)
                row("State", user.state)
            } header: {
                Text("Location").foregroundStyle(.tint)
            }

            Section {
                row("Registered", user.registered.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A detail row with a teal (accent) label and a default-coloured value.
    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(label).foregroundStyle(.tint)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        UserDetailView(user: .sample())
    }
}
#endif
