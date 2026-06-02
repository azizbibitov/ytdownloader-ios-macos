#if os(iOS)
import SwiftUI
import AVKit
import Photos

struct PlayerViewIOS: View {
    let url: URL
    @State private var viewModel = PlayerViewModel()
    @State private var isSavingToPhotos = false
    @State private var savedToPhotos = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .disabled(true)
            }

            controlsOverlay
        }
        .onTapGesture { viewModel.toggleControls() }
        .onAppear { viewModel.load(url: url) }
        .onDisappear { viewModel.cleanup() }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    @ViewBuilder
    private var controlsOverlay: some View {
        if viewModel.showControls {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear, .clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack {
                    // Top bar
                    HStack {
                        glassButton(icon: "xmark") { dismiss() }
                        Spacer()
                        glassButton(
                            icon: isSavingToPhotos ? nil : (savedToPhotos ? "checkmark.circle.fill" : "square.and.arrow.down"),
                            tint: savedToPhotos ? .green : .white,
                            loading: isSavingToPhotos
                        ) {
                            saveToPhotos()
                        }
                        .disabled(isSavingToPhotos || savedToPhotos)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()

                    // Center controls
                    HStack(spacing: 48) {
                        Button { viewModel.seek(by: -10) } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        Button { viewModel.togglePlayPause() } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.white)
                        }
                        Button { viewModel.seek(by: 10) } label: {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    // Seek bar
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { viewModel.duration > 0 ? viewModel.currentTime / viewModel.duration : 0 },
                                set: { viewModel.seek(to: $0) }
                            )
                        )
                        .tint(Color.ytAccent)

                        HStack {
                            Text(formattedTime(viewModel.currentTime))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white)
                            Spacer()
                            Text(formattedTime(viewModel.duration))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.showControls)
        }
    }

    @ViewBuilder
    private func glassButton(
        icon: String?,
        tint: Color = .white,
        loading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if loading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    Image(systemName: icon ?? "")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 45, height: 45)
        }
        .buttonStyle(GlassCircleButtonStyle())
    }

    private func saveToPhotos() {
        isSavingToPhotos = true
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { isSavingToPhotos = false }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, _ in
                DispatchQueue.main.async {
                    isSavingToPhotos = false
                    savedToPhotos = success
                }
            }
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .glassEffect(.regular.interactive(), in: .circle)
                .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
                .animation(.spring(duration: 0.2), value: configuration.isPressed)
        } else {
            configuration.label
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
                .animation(.spring(duration: 0.2), value: configuration.isPressed)
        }
    }
}
#endif
