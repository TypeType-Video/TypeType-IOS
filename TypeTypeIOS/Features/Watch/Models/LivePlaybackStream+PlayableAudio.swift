import Foundation

extension LivePlaybackStream {
  var playableAudioSources: [LivePlaybackAudioSource] {
    let sabr = audioStreams.filter { $0.isSABR && $0.isAppleAAC }
    let compatible = sabr.isEmpty
      ? audioStreams.filter { !$0.isSABR && $0.isAppleProviderAudio }
      : sabr
    var seen: Set<String> = []
    return compatible.filter { seen.insert($0.id).inserted }
  }
}
