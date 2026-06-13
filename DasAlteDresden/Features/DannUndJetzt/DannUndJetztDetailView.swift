import SwiftUI

struct DannUndJetztDetailView: View {
    let item: DannUndJetzt

    var body: some View {
        VStack(spacing: 0) {
            SliderCompareView(
                historicalURL: item.historicalImageURL,
                modernURL: item.modernImageURL,
                historicalYear: item.historicalYear,
                modernYear: item.modernYear
            )
            .frame(maxWidth: .infinity)
            .frame(height: 380)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.caption)
                        .font(.body)

                    if let year = item.historicalYear {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Aufnahme ca. \(year)")
                        }
                        .font(.callout)
                        .foregroundStyle(Color.appSepia)
                    }

                    HStack {
                        Image(systemName: "arrow.left.and.right")
                        Text("Schieberegler bewegen zum Vergleich")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Dann & Jetzt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
