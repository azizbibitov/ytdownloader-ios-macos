#if os(macOS)
import SwiftUI
import AVKit

struct PlayerViewMacOS: View {
    let url: URL
    @State private var viewModel = PlayerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(minWidth: 640, minHeight: 360)
            }

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.duration > 0 ? viewModel.currentTime / viewModel.duration : 0 },
                        set: { viewModel.seek(to: $0) }
                    )
                )
                .tint(.red)

                HStack {
                    Text(formattedTime(viewModel.currentTime))
                    Spacer()
                    Text(formattedTime(viewModel.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 24) {
                    Button { viewModel.seek(by: -10) } label: {
                        Image(systemName: "gobackward.10")
                    }
                    Button { viewModel.togglePlayPause() } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    Button { viewModel.seek(by: 10) } label: {
                        Image(systemName: "goforward.10")
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear { viewModel.load(url: url) }
        .onDisappear { viewModel.cleanup() }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
#endif
