//
//  AvatarView.swift
//  RandomUser
//

import SwiftUI

/// Circular avatar: the user's photo, or — while it loads or if it's missing — a
/// monogram of their initials over a colour derived deterministically from the uuid,
/// so the same user always gets the same colour.
struct AvatarView: View {
    let user: UserModel
    let url: String
    var size: CGFloat = 52

    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            monogram
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var monogram: some View {
        Circle()
            .fill(color.gradient)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    private var initials: String {
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    /// Stable across launches (String.hashValue is not), so colours don't shuffle.
    private var color: Color {
        let palette: [Color] = [.teal, .indigo, .pink, .orange, .purple, .blue, .green, .mint, .cyan, .brown]
        let seed = user.uuid.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[seed % palette.count]
    }
}

#if DEBUG
#Preview {
    HStack {
        AvatarView(user: .sample(uuid: "ada", first: "Ada", last: "Lovelace"), url: "")
        AvatarView(user: .sample(uuid: "gracehopper", first: "Grace", last: "Hopper"), url: "", size: 80)
    }
    .padding()
}
#endif
