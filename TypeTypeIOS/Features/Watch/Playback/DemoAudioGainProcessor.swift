import AVFoundation
import MediaToolbox

final class DemoAudioGainProcessor {
  let gain: Float
  var processesFloatAudio = false
  var processedFramesSinceMeterUpdate = 0
  let meterHandler: (Float) -> Void

  private init(
    gain: Float,
    meterHandler: @escaping (Float) -> Void
  ) {
    self.gain = gain
    self.meterHandler = meterHandler
  }

  static func makeTap(
    gain: Float,
    meterHandler: @escaping (Float) -> Void = { _ in }
  ) -> MTAudioProcessingTap? {
    let processor = DemoAudioGainProcessor(
      gain: min(3, max(1, gain)),
      meterHandler: meterHandler
    )
    let retained = Unmanaged.passRetained(processor)
    var callbacks = MTAudioProcessingTapCallbacks(
      version: kMTAudioProcessingTapCallbacksVersion_0,
      clientInfo: retained.toOpaque(),
      init: demoAudioTapInitialize,
      finalize: demoAudioTapFinalize,
      prepare: demoAudioTapPrepare,
      unprepare: demoAudioTapUnprepare,
      process: demoAudioTapProcess
    )
    var tap: MTAudioProcessingTap?
    let status = MTAudioProcessingTapCreate(
      kCFAllocatorDefault,
      &callbacks,
      kMTAudioProcessingTapCreationFlag_PostEffects,
      &tap
    )
    guard status == noErr, let tap else {
      retained.release()
      return nil
    }
    return tap
  }
}

private func demoAudioTapInitialize(
  tap: MTAudioProcessingTap,
  clientInfo: UnsafeMutableRawPointer?,
  tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
  tapStorageOut.pointee = clientInfo
}

private func demoAudioTapFinalize(tap: MTAudioProcessingTap) {
  let storage = MTAudioProcessingTapGetStorage(tap)
  Unmanaged<DemoAudioGainProcessor>
    .fromOpaque(storage)
    .release()
}

private func demoAudioTapPrepare(
  tap: MTAudioProcessingTap,
  maxFrames: CMItemCount,
  processingFormat: UnsafePointer<AudioStreamBasicDescription>
) {
  let processor = demoAudioGainProcessor(for: tap)
  processor.processesFloatAudio =
    processingFormat.pointee.mFormatID == kAudioFormatLinearPCM
      && processingFormat.pointee.mFormatFlags
        & kAudioFormatFlagIsFloat != 0
}

private func demoAudioTapUnprepare(tap: MTAudioProcessingTap) {}

private func demoAudioTapProcess(
  tap: MTAudioProcessingTap,
  numberFrames: CMItemCount,
  flags: MTAudioProcessingTapFlags,
  bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
  numberFramesOut: UnsafeMutablePointer<CMItemCount>,
  flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
  var sourceFlags = MTAudioProcessingTapFlags()
  var timeRange = CMTimeRange()
  var frames = CMItemCount()
  let status = MTAudioProcessingTapGetSourceAudio(
    tap,
    numberFrames,
    bufferListInOut,
    &sourceFlags,
    &timeRange,
    &frames
  )
  guard status == noErr else {
    numberFramesOut.pointee = 0
    return
  }
  numberFramesOut.pointee = frames
  flagsOut.pointee = sourceFlags

  let processor = demoAudioGainProcessor(for: tap)
  guard processor.processesFloatAudio else { return }
  let buffers = UnsafeMutableAudioBufferListPointer(bufferListInOut)
  var energy = 0.0
  var measuredSampleCount = 0
  for buffer in buffers {
    guard let data = buffer.mData else { continue }
    let sampleCount =
      Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
    let samples = data.assumingMemoryBound(to: Float.self)
    for index in 0..<sampleCount {
      let sourceSample = samples[index]
      energy += Double(sourceSample * sourceSample)
      measuredSampleCount += 1
      samples[index] = min(
        1,
        max(-1, sourceSample * processor.gain)
      )
    }
  }
  processor.processedFramesSinceMeterUpdate += Int(frames)
  guard
    processor.processedFramesSinceMeterUpdate >= 1_600,
    measuredSampleCount > 0
  else { return }
  processor.processedFramesSinceMeterUpdate = 0
  let rootMeanSquare = Float(sqrt(energy / Double(measuredSampleCount)))
  processor.meterHandler(min(1, rootMeanSquare * 4))
}

private func demoAudioGainProcessor(
  for tap: MTAudioProcessingTap
) -> DemoAudioGainProcessor {
  let storage = MTAudioProcessingTapGetStorage(tap)
  return Unmanaged<DemoAudioGainProcessor>
    .fromOpaque(storage)
    .takeUnretainedValue()
}
