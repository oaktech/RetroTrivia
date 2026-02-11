//
//  AudioManager.swift
//  RetroTrivia
//

import AudioToolbox
import AVFoundation
import SwiftUI

@Observable
class AudioManager {
    static let shared = AudioManager()

    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayer: AVAudioPlayer?
    private var currentMusicTrack: String?

    var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
            if isMusicEnabled {
                playMenuMusic()
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

    var isSoundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "isSoundEffectsEnabled")
        }
    }

    var soundEffectsVolume: Float {
        didSet {
            UserDefaults.standard.set(soundEffectsVolume, forKey: "soundEffectsVolume")
        }
    }

    private init() {
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        self.musicVolume = UserDefaults.standard.object(forKey: "musicVolume") as? Float ?? 0.5
        self.isSoundEffectsEnabled = UserDefaults.standard.object(forKey: "isSoundEffectsEnabled") as? Bool ?? true
        self.soundEffectsVolume = UserDefaults.standard.object(forKey: "soundEffectsVolume") as? Float ?? 0.8

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

    func playBackgroundMusic(named trackName: String) {
        guard isMusicEnabled else { return }

        // Don't restart if already playing this track
        if currentMusicTrack == trackName, backgroundMusicPlayer?.isPlaying == true {
            return
        }

        // Stop current music
        backgroundMusicPlayer?.stop()

        // Try to load music from bundle
        guard let url = Bundle.main.url(forResource: trackName, withExtension: "mp3") else {
            print("Music file '\(trackName).mp3' not found.")
            return
        }

        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = musicVolume
            backgroundMusicPlayer?.play()
            currentMusicTrack = trackName
            print("Playing music: \(trackName).mp3")
        } catch {
            print("Failed to play music: \(error)")
        }
    }

    func playMenuMusic() {
        playBackgroundMusic(named: "menu-music")
    }

    func playGameplayMusic() {
        playBackgroundMusic(named: "gameplay-music")
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

    func playTickSound() {
        guard isSoundEffectsEnabled else { return }
        AudioServicesPlaySystemSound(1057) // System "Tock" sound
    }

    func playSoundEffect(named name: String, withExtension ext: String = "mp3", volume: Float? = nil) {
        // Check if sound effects are enabled
        guard isSoundEffectsEnabled else {
            print("DEBUG: Sound effects disabled, skipping \(name).\(ext)")
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("DEBUG: Sound effect '\(name).\(ext)' NOT FOUND in bundle!")
            return
        }

        do {
            print("DEBUG: Playing sound effect: \(name).\(ext)")
            soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
            soundEffectPlayer?.volume = volume ?? soundEffectsVolume
            soundEffectPlayer?.play()
        } catch {
            print("DEBUG: Failed to play sound effect: \(error)")
        }
    }
}
