//
//  BadgeToastView.swift
//  RetroTrivia
//

import SwiftUI

struct BadgeToastView: View {
    let badge: Badge
    var isVisible: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: badge.iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(badge.iconColor))
                .shadow(color: Color(badge.iconColor), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text("BADGE UNLOCKED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                Text(badge.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color("NeonYellow"))
                    .shadow(color: Color("NeonYellow").opacity(0.5), radius: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("RetroPurple").opacity(0.95))
                .stroke(Color("NeonYellow").opacity(0.5), lineWidth: 1)
                .shadow(color: Color("NeonYellow").opacity(0.3), radius: 10)
        )
        .offset(y: isVisible ? 0 : -120)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
    }
}

#Preview {
    ZStack {
        Color.black
        BadgeToastView(badge: Badge.all[0], isVisible: true)
    }
}
