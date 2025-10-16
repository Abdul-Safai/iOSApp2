// iOSApp2/Views/Sharing/FlipCardView.swift
import SwiftUI

struct FlipCardView<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    private let front: Front
    private let back: Back

    init(isFlipped: Binding<Bool>,
         @ViewBuilder front: () -> Front,
         @ViewBuilder back: () -> Back) {
        _isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .shadow(radius: 6)

            ZStack {
                front.opacity(isFlipped ? 0 : 1)
                back
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0),
                          axis: (x: 0, y: 1, z: 0),
                          perspective: 0.75)
        .animation(.easeInOut(duration: 0.35), value: isFlipped)
    }
}
