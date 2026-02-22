//
//  NotificationManager.swift
//  RetroTrivia
//

import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    // MARK: - Notification Categories

    enum Category: String {
        case dailyChallenge = "DAILY_CHALLENGE"
        case streakReminder = "STREAK_REMINDER"
        case leaderboard = "LEADERBOARD"
    }

    // MARK: - Settings Keys

    private static let dailyChallengeEnabledKey = "notifications.dailyChallenge"
    private static let streakReminderEnabledKey = "notifications.streakReminder"
    private static let leaderboardEnabledKey = "notifications.leaderboard"
    private static let permissionRequestedKey = "notifications.permissionRequested"

    // MARK: - Observable State

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var dailyChallengeEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyChallengeEnabled, forKey: Self.dailyChallengeEnabledKey) }
    }

    var streakReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(streakReminderEnabled, forKey: Self.streakReminderEnabledKey) }
    }

    var leaderboardEnabled: Bool {
        didSet { UserDefaults.standard.set(leaderboardEnabled, forKey: Self.leaderboardEnabledKey) }
    }

    var hasRequestedPermission: Bool {
        UserDefaults.standard.bool(forKey: Self.permissionRequestedKey)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    // MARK: - Init

    private init() {
        self.dailyChallengeEnabled = UserDefaults.standard.object(forKey: Self.dailyChallengeEnabledKey) as? Bool ?? true
        self.streakReminderEnabled = UserDefaults.standard.object(forKey: Self.streakReminderEnabledKey) as? Bool ?? true
        self.leaderboardEnabled = UserDefaults.standard.object(forKey: Self.leaderboardEnabledKey) as? Bool ?? true
    }

    // MARK: - Permission

    /// Request notification permission. Call after the user's first completed game.
    func requestPermission() async -> Bool {
        UserDefaults.standard.set(true, forKey: Self.permissionRequestedKey)
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Daily Challenge Notification

    /// Schedule a daily notification reminding the user about the daily challenge.
    /// Fires at 10:00 AM local time if they haven't played yet.
    func scheduleDailyChallengeReminder() {
        guard dailyChallengeEnabled else { return }
        cancelNotifications(for: .dailyChallenge)

        let content = UNMutableNotificationContent()
        content.title = "Daily 80s Challenge"
        content.body = "Today's challenge is waiting! Test your 80s music knowledge."
        content.sound = .default
        content.categoryIdentifier = Category.dailyChallenge.rawValue

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_challenge_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily challenge notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Streak Reminder

    /// Schedule an evening reminder if the user has an active streak.
    func scheduleStreakReminder(currentStreak: Int) {
        guard streakReminderEnabled, currentStreak > 0 else { return }
        cancelNotifications(for: .streakReminder)

        let content = UNMutableNotificationContent()
        content.title = "Don't Lose Your Streak!"
        content.body = "You're on a \(currentStreak)-day streak. Play today's challenge to keep it alive!"
        content.sound = .default
        content.categoryIdentifier = Category.streakReminder.rawValue

        // Fire at 7:00 PM if they haven't played
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule streak reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel streak reminder (call when the user completes today's challenge).
    func cancelStreakReminder() {
        cancelNotifications(for: .streakReminder)
    }

    // MARK: - Leaderboard Nudges

    /// Schedule a notification when the user's leaderboard rank has dropped.
    func scheduleLeaderboardNudge(previousRank: Int, currentRank: Int) {
        guard leaderboardEnabled, currentRank > previousRank else { return }
        cancelNotifications(for: .leaderboard)

        let content = UNMutableNotificationContent()
        content.title = "You've Been Passed!"
        content.body = "You dropped from #\(previousRank) to #\(currentRank) on the leaderboard. Play now to reclaim your spot!"
        content.sound = .default
        content.categoryIdentifier = Category.leaderboard.rawValue

        // Slight delay so it doesn't fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "leaderboard_rank_drop",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule leaderboard nudge: \(error.localizedDescription)")
            }
        }
    }

    /// Schedule a weekly leaderboard reset reminder (Monday at 9 AM).
    func scheduleWeeklyLeaderboardReminder() {
        guard leaderboardEnabled else { return }

        let identifier = "leaderboard_weekly"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "New Week, New Leaderboard"
        content.body = "The leaderboard resets today. Be the first to claim #1!"
        content.sound = .default
        content.categoryIdentifier = Category.leaderboard.rawValue

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule weekly leaderboard reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Notify the user they're close to the top of the leaderboard.
    func scheduleLeaderboardCloseToTopNudge(currentRank: Int, topRank: Int) {
        guard leaderboardEnabled, currentRank > topRank, currentRank <= topRank + 10 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Almost There!"
        content.body = "You're #\(currentRank) — just \(currentRank - topRank) spots from the top. One great run could do it!"
        content.sound = .default
        content.categoryIdentifier = Category.leaderboard.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour delay

        let request = UNNotificationRequest(
            identifier: "leaderboard_close_to_top",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule close-to-top nudge: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Lapsed User Win-Back

    /// Schedule escalating re-engagement notifications for inactive users.
    func scheduleLapsedUserReminders(highScore: Int) {
        let reminders: [(id: String, delay: TimeInterval, title: String, body: String)] = [
            (
                "lapsed_3day",
                3 * 86400,
                "The 80s Miss You!",
                "Come back for a quick round of 80s trivia."
            ),
            (
                "lapsed_7day",
                7 * 86400,
                "Your Record Still Stands",
                highScore > 0
                    ? "Your high score of \(highScore) is still holding. Can you beat it?"
                    : "Your first high score is waiting. Come set the bar!"
            ),
            (
                "lapsed_14day",
                14 * 86400,
                "We've Missed You",
                "It's been a while — jump back in for some 80s music trivia!"
            ),
        ]

        // Remove any existing lapsed reminders
        let identifiers = reminders.map { $0.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminder.delay, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule lapsed reminder \(reminder.id): \(error.localizedDescription)")
                }
            }
        }
    }

    /// Cancel lapsed user reminders (call when the user opens the app).
    func cancelLapsedUserReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["lapsed_3day", "lapsed_7day", "lapsed_14day"]
        )
    }

    // MARK: - Helpers

    private func cancelNotifications(for category: Category) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
