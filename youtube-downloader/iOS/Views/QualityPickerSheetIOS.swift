#if os(iOS)
import SwiftUI

struct QualityPickerSheetIOS: View {
    let video: VideoInfo
    @Binding var selectedQuality: QualityOption?
    var onDownload: ((QualityOption) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.ytBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                handle
                titleRow
                Divider().background(Color.ytDivider)
                qualityList
                downloadButton
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.ytBackground)
    }

    private var handle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.ytDivider)
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var titleRow: some View {
        HStack {
            Text("Select Quality")
                .font(.headline)
                .foregroundStyle(Color.ytTextPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ytTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var qualityList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(video.qualities) { quality in
                    QualityRowView(quality: quality, isSelected: selectedQuality?.id == quality.id) {
                        selectedQuality = quality
                    }
                    if quality.id != video.qualities.last?.id {
                        Divider()
                            .background(Color.ytDivider)
                            .padding(.leading, 20)
                    }
                }
            }
        }
    }

    private var downloadButton: some View {
        Button {
            if let quality = selectedQuality {
                onDownload?(quality)
            }
            dismiss()
        } label: {
            Text("Download")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(selectedQuality == nil ? Color.ytAccent.opacity(0.4) : Color.ytAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedQuality == nil)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.15), value: selectedQuality == nil)
    }
}

private struct QualityRowView: View {
    let quality: QualityOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: quality.isAudioOnly ? "music.note" : "video.fill")
                    .foregroundStyle(isSelected ? Color.ytAccent : Color.ytTextSecondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(quality.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.ytTextPrimary)
                    Text(quality.fileExtension.uppercased())
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ytAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? Color.ytAccent.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
#endif
