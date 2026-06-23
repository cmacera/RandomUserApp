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
                AsyncImage(url: URL(string: user.pictureURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.quaternary)
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Name", value: user.fullName)
                LabeledContent("Gender", value: user.gender.capitalized)
                LabeledContent("Email", value: user.email)
            }

            Section("Location") {
                LabeledContent("Street", value: user.street)
                LabeledContent("City", value: user.city)
                LabeledContent("State", value: user.state)
            }

            Section {
                LabeledContent(
                    "Registered",
                    value: user.registered.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        UserDetailView(user: .sample())
    }
}
#endif
