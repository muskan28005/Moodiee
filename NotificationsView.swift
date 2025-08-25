import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var moodStore: MoodStore
    @State private var diaryLogs: [String: String] = UserDefaults.standard.dictionary(forKey: "diaryLogs") as? [String: String] ?? [:]
    
    var body: some View {
        List {
            Section(header: Text("Smart Suggestions")) {
                ForEach(generateSuggestions(), id: \.self) { suggestion in
                    Text(suggestion)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateSuggestions() -> [String] {
        var suggestions: [String] = []
        
        let recentMoods = moodStore.moodLogs.sorted(by: { $0.key > $1.key })
        let moodValues: [String: Int] = ["Awful": 1, "Sad": 2, "Neutral": 3, "Happy": 4, "Delighted": 5]
        let recentEntries = diaryLogs.sorted { $0.key > $1.key }
        
        if let lastEntryDate = recentEntries.first?.key {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let lastDate = formatter.date(from: lastEntryDate) {
                let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
                if days >= 3 {
                    suggestions.append("It's been \(days) days since your last journal. Want to write something?")
                }
            }
        }

        let lastThree = recentMoods.prefix(3).compactMap { moodValues[$0.value] }
        if lastThree.allSatisfy({ $0 <= 2 }) {
            suggestions.append("You've felt a bit low lately. Want to try something uplifting?")
        } else if lastThree.allSatisfy({ $0 >= 4 }) {
            suggestions.append("You've had great moods recently! Would you like to reflect on what’s working?")
        }

        if suggestions.isEmpty {
            suggestions.append("All good! No suggestions for now. Keep tracking 😊")
        }
        
        return suggestions
    }
}
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let moodStore = MoodStore()
        moodStore.moodLogs = [
            "2024-05-01": "Sad",
            "2024-05-02": "Awful",
            "2024-05-03": "Sad"
        ]
        UserDefaults.standard.set(["2024-04-30": "Had a rough day."], forKey: "diaryLogs")
        
        return NavigationStack {
            NotificationsView()
                .environmentObject(moodStore)
        }
    }
}
