import SwiftUI

struct ProgressRing: View {
    let progress: Double   // 0.0...1.0
    private var clamped: Double { max(0, min(1, progress)) }

    var body: some View {
        ZStack {
            Circle().stroke(.gray.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((clamped * 10).rounded()))/10")
                .font(.caption)
                .monospacedDigit()
        }
        .frame(width: 34, height: 34)
    }
}
