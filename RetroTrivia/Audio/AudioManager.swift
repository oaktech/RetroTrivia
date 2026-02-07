//
//  AudioManager.swift
//  RetroTrivia
//

import AVFoundation
import SwiftUI

@Observable
class AudioManager {
    static let shared = AudioManager()

    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayer: AVAudioPlayer?

    var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
            if isMusicEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }

    var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
            backgroundMusicPlayer?.volume = musicVolume
        }
    }

    private init() {
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        self.musicVolume = UserDefaults.standard.object(forKey: "musicVolume") as? Float ?? 0.5

        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func playBackgroundMusic() {
        guard isMusicEnabled else { return }

        // Try to load background music from bundle
        guard let url = Bundle.main.url(forResource: "background-music", withExtension: "mp3") else {
            print("Background music file not found. Add 'background-music.mp3' to the project.")
            return
        }

        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = musicVolume
            backgroundMusicPlayer?.play()
            print("Background music started")
        } catch {
            print("Failed to play background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }

    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        backgroundMusicPlayer?.play()
    }

    func playSoundEffect(named name: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Sound effect '\(name).\(ext)' not found")
            return
        }

        do {
            soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
            soundEffectPlayer?.volume = 0.8
            soundEffectPlayer?.play()
        } catch {
            print("Failed to play sound effect: \(error)")
        }
    }
}
