import SwiftUI

private struct MomLibraryVideo: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let youtubeURL: String
    let thumbnailURL: String
}

private struct MomLibrarySection: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let videos: [MomLibraryVideo]
}

struct MomLibraryView: View {
    let accentColor: Color
    let backgroundColor: Color

    @Environment(\.dismiss) private var dismiss

    private let sections: [MomLibrarySection] = [
        MomLibrarySection(
            title: "Pregnancy Nutrition",
            description: "Healthy meal planning, hydration, and essential nutrients.",
            videos: [
                MomLibraryVideo(
                    title: "Pregnancy Nutrition Basics",
                    subtitle: "What to eat in each trimester",
                    youtubeURL: "https://www.youtube.com/watch?v=5g4n0VQfNqM",
                    thumbnailURL: "https://img.youtube.com/vi/5g4n0VQfNqM/hqdefault.jpg"
                ),
                MomLibraryVideo(
                    title: "Healthy Pregnancy Meal Ideas",
                    subtitle: "Simple meals for busy moms",
                    youtubeURL: "https://www.youtube.com/watch?v=o6rG7XkLk2Q",
                    thumbnailURL: "https://img.youtube.com/vi/o6rG7XkLk2Q/hqdefault.jpg"
                )
            ]
        ),
        MomLibrarySection(
            title: "Safe Pregnancy Exercises",
            description: "Gentle movement routines to stay active and reduce stress.",
            videos: [
                MomLibraryVideo(
                    title: "Prenatal Workout for Beginners",
                    subtitle: "Low-impact full-body routine",
                    youtubeURL: "https://www.youtube.com/watch?v=44fYnoSLL5c",
                    thumbnailURL: "https://img.youtube.com/vi/44fYnoSLL5c/hqdefault.jpg"
                ),
                MomLibraryVideo(
                    title: "Pregnancy Yoga Flow",
                    subtitle: "Relaxation and stretching",
                    youtubeURL: "https://www.youtube.com/watch?v=4C-gxOE0j7s",
                    thumbnailURL: "https://img.youtube.com/vi/4C-gxOE0j7s/hqdefault.jpg"
                )
            ]
        ),
        MomLibrarySection(
            title: "Baby Feeding and Care",
            description: "Trusted guidance on infant feeding and newborn routines.",
            videos: [
                MomLibraryVideo(
                    title: "Baby Feeding Basics",
                    subtitle: "Breastfeeding and bottle-feeding tips",
                    youtubeURL: "https://www.youtube.com/watch?v=6W4YI5sQGJQ",
                    thumbnailURL: "https://img.youtube.com/vi/6W4YI5sQGJQ/hqdefault.jpg"
                ),
                MomLibraryVideo(
                    title: "Newborn Daily Care",
                    subtitle: "Bathing, burping, and sleep essentials",
                    youtubeURL: "https://www.youtube.com/watch?v=2vqhTU16Dr4",
                    thumbnailURL: "https://img.youtube.com/vi/2vqhTU16Dr4/hqdefault.jpg"
                )
            ]
        )
    ]

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    introCard

                    ForEach(sections) { section in
                        sectionBlock(section)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
            }
            Text("Library")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
            Spacer()
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Educational videos for moms and families")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.8))
            Text("Tap any card to open YouTube and watch trusted guidance on food, exercise, and baby care.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionBlock(_ section: MomLibrarySection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))
            Text(section.description)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.48))

            VStack(spacing: 10) {
                ForEach(section.videos) { video in
                    videoCard(video)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func videoCard(_ video: MomLibraryVideo) -> some View {
        Link(destination: URL(string: video.youtubeURL)!) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            Color.black.opacity(0.08)
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    }
                }
                .frame(width: 112, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .multilineTextAlignment(.leading)
                    Text(video.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.48))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            .padding(10)
            .background(accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        MomLibraryView(
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97)
        )
    }
}
