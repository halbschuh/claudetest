import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                placeholderView(systemImage: "photo")
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            @unknown default:
                placeholderView(systemImage: "photo")
            }
        }
    }

    private func placeholderView(systemImage: String) -> some View {
        Color(.systemGray5)
            .overlay {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
