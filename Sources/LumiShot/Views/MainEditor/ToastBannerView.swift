import SwiftUI

struct ToastBannerView: View {
    @Binding var message: String?
    var dismissToken: Int

    private let displayDurationNanoseconds: UInt64 = 2_500_000_000

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            if let text = message {
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background {
                        Capsule(style: .continuous)
                            .fill(.black.opacity(0.72))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            }
                    }
                    .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: dismissToken) {
                        guard message != nil else { return }
                        try? await Task.sleep(nanoseconds: displayDurationNanoseconds)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            message = nil
                        }
                    }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: message)
        .allowsHitTesting(false)
    }
}
