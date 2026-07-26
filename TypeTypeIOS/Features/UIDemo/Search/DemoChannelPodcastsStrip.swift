import SwiftUI

struct DemoChannelPodcastsStrip: View {
  let channel: DemoSearchChannel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Podcasts")
            .font(.headline)
          Text("Podcast playlists from this channel")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        NavigationLink("See all") {
          DemoPodcastsView(
            podcast: DemoChannelCatalog.podcasts(for: channel).first
          )
        }
        .font(.caption.weight(.semibold))
      }

      ScrollView(.horizontal) {
        HStack(spacing: 12) {
          ForEach(DemoChannelCatalog.podcasts(for: channel)) { podcast in
            NavigationLink {
              DemoPodcastsView(podcast: podcast)
            } label: {
              VStack(alignment: .leading, spacing: 7) {
                Image(podcast.artwork.rawValue)
                  .resizable()
                  .interpolation(.none)
                  .scaledToFit()
                  .padding(14)
                  .frame(width: 112, height: 112)
                  .background(Color.purple.opacity(0.16))
                  .clipShape(RoundedRectangle(cornerRadius: 15))
                Text(podcast.title)
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.primary)
                  .lineLimit(1)
                Text("\(podcast.episodeCount) episodes")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
              .frame(width: 112, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("demo.channel.podcast.\(podcast.id)")
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}
