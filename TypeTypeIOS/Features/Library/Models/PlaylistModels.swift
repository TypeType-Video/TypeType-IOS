import Foundation

struct PlaylistVideoEntry: Decodable, Identifiable {
  let id: String
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
  let position: Int
}

struct PlaylistSummary: Decodable, Identifiable {
  let id: String
  let name: String
  let description: String
  let videos: [PlaylistVideoEntry]
  let createdAt: Int64
}
