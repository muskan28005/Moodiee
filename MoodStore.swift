import Foundation
import Combine

class MoodStore: ObservableObject {
    @Published var moodLogs: [String: String] {
        didSet {
            KeychainHelper.standard.save(moodLogs, forKey: "moodLogs")
        }
    }

    @Published var diaryLogs: [String: String] {
        didSet {
            KeychainHelper.standard.save(diaryLogs, forKey: "diaryLogs")
        }
    }

    init() {
        self.moodLogs = KeychainHelper.standard.read(forKey: "moodLogs") ?? [:]
        self.diaryLogs = KeychainHelper.standard.read(forKey: "diaryLogs") ?? [:]
    }

    func saveMood(for date: Date, mood: String) {
        let key = formattedDate(date)
        moodLogs[key] = mood
    }

    func saveDiary(for date: Date, text: String) {
        let key = formattedDate(date)
        diaryLogs[key] = text
    }

    func getMood(for date: Date) -> String? {
        return moodLogs[formattedDate(date)]
    }

    func getDiary(for date: Date) -> String? {
        return diaryLogs[formattedDate(date)]
    }
    
    func clearAllData() {
        moodLogs = [:]
        diaryLogs = [:]
        UserDefaults.standard.removeObject(forKey: "moodLogs")
        UserDefaults.standard.removeObject(forKey: "diaryLogs")
    }


    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
