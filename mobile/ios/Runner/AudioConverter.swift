import AVFoundation
import Foundation

/// Нативная конвертация audio/video в WAV PCM 16-bit 44.1kHz stereo
/// + crop по time range. Работает и на симуляторе, и на реальном устройстве
/// (использует AVFoundation, доступный на всех iOS версиях ≥ 13).
enum AudioConverterError: Error {
    case missingArgument(String)
    case sourceNotFound(String)
    case noAudioTrack
    case readerInitFailed(String)
    case writerInitFailed(String)
    case readFailed(String)
    case invalidRange
    case exportFailed(String)
}

final class AudioConverter {
    private let sampleRate: Double = 44_100
    private let channels: UInt32 = 2

    /// Конвертирует source в WAV. Возвращает (path, durationMs).
    func convertToWav(sourcePath: String, targetPath: String) async throws -> (path: String, durationMs: Int) {
        let srcUrl = URL(fileURLWithPath: sourcePath)
        let dstUrl = URL(fileURLWithPath: targetPath)
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw AudioConverterError.sourceNotFound(sourcePath)
        }
        try? FileManager.default.removeItem(at: dstUrl)
        try FileManager.default.createDirectory(
            at: dstUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let asset = AVURLAsset(url: srcUrl)
        let durationSec = CMTimeGetSeconds(asset.duration)
        try await transcodePCM(
            asset: asset,
            target: dstUrl,
            timeRange: CMTimeRange(start: .zero, duration: asset.duration)
        )
        return (targetPath, Int(durationSec * 1000))
    }

    /// Crop по диапазону. start/end в миллисекундах. Возвращает path.
    func crop(sourcePath: String, targetPath: String, startMs: Int, endMs: Int) async throws -> String {
        let srcUrl = URL(fileURLWithPath: sourcePath)
        let dstUrl = URL(fileURLWithPath: targetPath)
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw AudioConverterError.sourceNotFound(sourcePath)
        }
        guard endMs > startMs else { throw AudioConverterError.invalidRange }
        try? FileManager.default.removeItem(at: dstUrl)
        try FileManager.default.createDirectory(
            at: dstUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let asset = AVURLAsset(url: srcUrl)
        let start = CMTime(value: CMTimeValue(startMs), timescale: 1000)
        let end = CMTime(value: CMTimeValue(endMs), timescale: 1000)
        let range = CMTimeRange(start: start, duration: end - start)
        try await transcodePCM(asset: asset, target: dstUrl, timeRange: range)
        return targetPath
    }

    // MARK: - Internals

    private func transcodePCM(
        asset: AVAsset,
        target: URL,
        timeRange: CMTimeRange
    ) async throws {
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw AudioConverterError.noAudioTrack
        }

        // PCM-выходные настройки
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]

        let reader: AVAssetReader
        do { reader = try AVAssetReader(asset: asset) } catch {
            throw AudioConverterError.readerInitFailed(error.localizedDescription)
        }
        reader.timeRange = timeRange

        let readerOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: outputSettings
        )
        readerOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(readerOutput) else {
            throw AudioConverterError.readerInitFailed("cannot add output")
        }
        reader.add(readerOutput)

        let writer: AVAssetWriter
        do { writer = try AVAssetWriter(outputURL: target, fileType: .wav) } catch {
            throw AudioConverterError.writerInitFailed(error.localizedDescription)
        }
        let writerInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: outputSettings
        )
        writerInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(writerInput) else {
            throw AudioConverterError.writerInitFailed("cannot add input")
        }
        writer.add(writerInput)

        guard reader.startReading() else {
            throw AudioConverterError.readerInitFailed(
                reader.error?.localizedDescription ?? "startReading failed"
            )
        }
        guard writer.startWriting() else {
            throw AudioConverterError.writerInitFailed(
                writer.error?.localizedDescription ?? "startWriting failed"
            )
        }
        writer.startSession(atSourceTime: timeRange.start)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let queue = DispatchQueue(label: "mp3craft.audio.convert")
            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if reader.status != .reading {
                        writerInput.markAsFinished()
                        if reader.status == .failed {
                            cont.resume(throwing: AudioConverterError.readFailed(
                                reader.error?.localizedDescription ?? "reader failed"
                            ))
                            return
                        }
                        writer.finishWriting {
                            if writer.status == .completed {
                                cont.resume()
                            } else {
                                cont.resume(throwing: AudioConverterError.exportFailed(
                                    writer.error?.localizedDescription ?? "writer failed"
                                ))
                            }
                        }
                        return
                    }
                    if let buffer = readerOutput.copyNextSampleBuffer() {
                        writerInput.append(buffer)
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                cont.resume()
                            } else {
                                cont.resume(throwing: AudioConverterError.exportFailed(
                                    writer.error?.localizedDescription ?? "writer failed"
                                ))
                            }
                        }
                        return
                    }
                }
            }
        }
    }
}
