import SwiftUI

/// Apple HIG-compliant onboarding:
/// - Max 3 welcome pages focused on BENEFITS (not mechanics)
/// - Let people jump right in
/// - No permissions requested here (defer to context)
/// - Skippable
/// - Uses the app's visual language

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [(image: String, title: String, subtitle: String)] = [
        (
            "text.below.photo",
            "Read naturally\non camera",
            "Rec is a teleprompter that lives in your Mac's notch — invisible to everyone but you."
        ),
        (
            "waveform",
            "Your voice\nsets the pace",
            "Switch to Voice mode and the text follows your speech in real-time. Read fast or slow — it keeps up."
        ),
        (
            "eye.slash",
            "Hidden from\nscreen sharing",
            "Stealth mode keeps Rec invisible during calls, recordings, and screenshots. Your secret tool."
        ),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { } // block clicks through

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pageView(i)
                            .tag(i)
                    }
                }
                .tabViewStyle(.automatic)
                .frame(height: 280)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? .white : .white.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 20)
                .animation(.easeOut(duration: 0.2), value: currentPage)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            currentPage += 1
                        }
                    } else {
                        finish()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(.purple, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)

                // Skip
                if currentPage < pages.count - 1 {
                    Button { finish() } label: {
                        Text("Skip")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }

                Spacer().frame(height: 20)
            }
            .frame(width: 340, height: 440)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(nsColor: NSColor(white: 0.1, alpha: 0.95)))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.4), radius: 40, y: 15)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Page

    private func pageView(_ index: Int) -> some View {
        let page = pages[index]
        return VStack(spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: page.image)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.purple)
                .frame(height: 50)

            // Title — large, bold, multiline
            Text(page.title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(2)

            // Subtitle — benefit-focused
            Text(page.subtitle)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.5))
                .lineSpacing(3)
                .frame(maxWidth: 260)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.25)) {
            appState.onboardingCompleted = true
            isPresented = false
        }
    }
}
