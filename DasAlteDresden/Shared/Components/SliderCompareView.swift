import SwiftUI

struct SliderCompareView: View {
    let historicalURL: URL
    let modernURL: URL
    let historicalYear: Int?
    let modernYear: Int?

    @State private var position: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                modernImage
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                historicalImage
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: geo.size.width * position)
                    }

                divider(in: geo)
                labels(in: geo)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = max(0.02, min(0.98, value.location.x / geo.size.width))
                    }
            )
            .clipped()
        }
    }

    private var historicalImage: some View {
        AsyncImage(url: historicalURL) { phase in
            switch phase {
            case .success(let img): img.resizable().scaledToFill()
            default: Color.appParchment
            }
        }
    }

    private var modernImage: some View {
        AsyncImage(url: modernURL) { phase in
            switch phase {
            case .success(let img): img.resizable().scaledToFill()
            default: Color.secondary.opacity(0.2)
            }
        }
    }

    private func divider(in geo: GeometryProxy) -> some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .frame(width: 2)

            Circle()
                .fill(.white)
                .frame(width: 44, height: 44)
                .shadow(radius: 6)
                .overlay {
                    Image(systemName: "arrow.left.and.right")
                        .font(.callout.bold())
                        .foregroundStyle(Color.appSepia)
                }
        }
        .frame(maxHeight: .infinity)
        .offset(x: geo.size.width * position - 1)
    }

    private func labels(in geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                if let y = historicalYear {
                    label("\(y)")
                }
                Spacer()
                if let y = modernYear {
                    label("heute (\(y))")
                }
            }
            .padding(12)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
