import Foundation
import AVFoundation

final class AudioEngine {
    enum Track {
        case target
        case adapted
    }

    enum AudioError: LocalizedError {
        case engineStartFailed(String)
        var errorDescription: String? { "Audio preview unavailable: \(self)" }
    }

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private let queue = DispatchQueue(label: "AmpWhisper.AudioEngine")

    var isPlaying: Bool { player?.isPlaying ?? false }

    func play(knobs: [String: Int]) throws {
        stop()
        let newEngine = AVAudioEngine()
        let newPlayer = AVAudioPlayerNode()
        newEngine.attach(newPlayer)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)
        do {
            try newEngine.start()
        } catch {
            throw AudioError.engineStartFailed(error.localizedDescription)
        }
        self.engine = newEngine
        self.player = newPlayer
        guard let buffer = Self.renderBuffer(knobs: knobs, format: format) else {
            throw AudioError.engineStartFailed("Unable to allocate audio buffer")
        }
        newPlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        newPlayer.play()
    }

    func stop() {
        if let player = player {
            player.stop()
        }
        if let engine = engine {
            queue.async {
                engine.stop()
            }
        }
        engine = nil
        player = nil
    }

    static func renderBuffer(knobs: [String: Int], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = 2.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount

        let gain = Double(knobs["gain"] ?? 5) / 10.0
        let treble = Double(knobs["treble"] ?? 5) / 10.0
        let bass = Double(knobs["bass"] ?? 5) / 10.0
        let level = 0.08 + Double(knobs["level"] ?? 5) / 10.0 * 0.12

        let root = 82.41
        let chordRatios: [Double] = [1.0, 1.5, 2.0, 2.5, 3.0]
        let filterAlpha = 0.05 + treble * 0.9
        let lowCutAlpha = 0.002 + bass * 0.02
        var lastOut = 0.0
        var lastLow = 0.0

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let noteIndex = Int(t * 4.0) % chordRatios.count
            let freq = root * chordRatios[noteIndex]
            let phase = 2.0 * .pi * freq * t
            var sample = sin(phase) + 0.4 * sin(2 * phase) + 0.2 * sin(3 * phase)

            sample = tanh(sample * (1.0 + gain * 5.0)) / (1.0 + gain * 1.2)

            lastOut += filterAlpha * (sample - lastOut)
            lastLow += lowCutAlpha * (sample - lastLow)
            let shaped = lastOut - lastLow * 0.5

            let envelope = min(1.0, Double(frame) / 800.0) * (0.85 + 0.15 * sin(2 * .pi * t * 1.5))
            channel[frame] = Float(shaped * level * envelope)
        }
        return buffer
    }
}
