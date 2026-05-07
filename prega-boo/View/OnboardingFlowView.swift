import SwiftUI

struct OnboardingFlowView: View {
    private let controller = OnboardingController()
    @State private var pageIndex = 0
    @State private var showBloomWelcome = false

    private var pages: [OnboardingPage] {
        controller.loadPages()
    }

    var body: some View {
        Group {
            if showBloomWelcome {
                BloomWelcomeView(model: BloomWelcomeController().loadModel())
            } else {
                let safeIndex = min(max(pageIndex, 0), pages.count - 1)
                let page = pages[safeIndex]

                OnboardingScreenView(
                    model: OnboardingModel(
                        title: page.title,
                        subtitle: page.subtitle,
                        message: page.message,
                        backgroundColor: controller.backgroundColor,
                        accentColor: controller.accentColor,
                        illustrationAssetName: page.illustrationAssetName,
                        isCompact: page.isCompact,
                        primaryButtonTitle: page.primaryButtonTitle,
                        pageCount: pages.count,
                        currentPageIndex: safeIndex
                    ),
                    onSkip: {
                        // Skip bypasses the rest of the onboarding entirely.
                        withAnimation(.easeInOut) { showBloomWelcome = true }
                    },
                    onNext: {
                        withAnimation(.easeInOut) {
                            if safeIndex >= pages.count - 1 {
                                showBloomWelcome = true
                            } else {
                                pageIndex = safeIndex + 1
                            }
                        }
                    },
                    onPrimaryAction: {
                        withAnimation(.easeInOut) { showBloomWelcome = true }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: pageIndex)
        .animation(.easeInOut, value: showBloomWelcome)
    }
}

#Preview {
    OnboardingFlowView()
}
