import SwiftUI
import WebKit

// MARK: - YouTube Web View

struct YouTubePlayerView: UIViewRepresentable {
    let videoUrl: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Convert YouTube URL to embed URL
        guard let embedUrl = youtubeEmbedUrl(from: videoUrl),
              let url = URL(string: embedUrl) else {
            // If not a YouTube link, try loading directly
            if let url = URL(string: videoUrl) {
                webView.load(URLRequest(url: url))
            }
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Converts various YouTube URL formats to an embeddable URL
    private func youtubeEmbedUrl(from urlString: String) -> String? {
        var videoId: String?

        if urlString.contains("youtu.be/") {
            // Short URL: https://youtu.be/VIDEO_ID
            videoId = urlString.components(separatedBy: "youtu.be/").last?
                .components(separatedBy: "?").first
        } else if urlString.contains("youtube.com/watch") {
            // Standard URL: https://www.youtube.com/watch?v=VIDEO_ID
            let components = URLComponents(string: urlString)
            videoId = components?.queryItems?.first(where: { $0.name == "v" })?.value
        } else if urlString.contains("youtube.com/embed/") {
            // Already an embed URL
            return urlString
        }

        guard let id = videoId, !id.isEmpty else { return nil }
        return "https://www.youtube.com/embed/\(id)?playsinline=1&autoplay=1"
    }
}

// MARK: - JPMR Video View

struct JPMRVideoView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var videoUrl: String?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView("Loading video…")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let videoUrl {
                YouTubePlayerView(videoUrl: videoUrl)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView {
                    Label("Video Unavailable", systemImage: "video.slash")
                } description: {
                    if let error = store.videoErrorMessage {
                        Text(error)
                            .font(.caption)
                    } else {
                        Text("The tutorial video could not be loaded. Please try again later.")
                    }
                }
                .foregroundStyle(.white)
            }
        }
        .navigationTitle("Video Tutorial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadVideo()
        }
    }

    private func loadVideo() {
        if let url = store.jpmrVideoUrl {
            videoUrl = url
            isLoading = false
        } else {
            Task {
                await store.fetchJpmrVideoUrl()
                videoUrl = store.jpmrVideoUrl
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        JPMRVideoView()
            .environment(CalmCentreStore.shared)
    }
}
