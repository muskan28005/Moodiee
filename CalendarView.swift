import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var moodStore: MoodStore
    @State private var selectedDate: Date = Date()
    @State private var selectedDay: Int? = nil

    let moodEmojis = [
        "Delighted": "😁",
        "Happy": "😊",
        "Neutral": "😐",
        "Sad": "😞",
        "Awful": "😖"
    ]

    let columns = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 10), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerView
                daysOfWeekView()
                calendarGrid

                // Diary entry preview panel
                if let day = selectedDay,
                   let entry = moodStore.diaryLogs[formattedDateKey(for: day)] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diary Entry")
                            .font(.headline)
                        ScrollView {
                            Text(entry)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 24)
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Mood Calendar")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))

            HStack(spacing: 48) {
                CircleIconButton(systemName: "chevron.left") {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
                    selectedDay = nil
                }

                Text(formattedMonthYear(selectedDate))
                    .font(.title2.bold())

                CircleIconButton(systemName: "chevron.right") {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? Date()
                    selectedDay = nil
                }
            }
        }
    }

    private var calendarGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(emptyDaysBeforeMonth(for: selectedDate), id: \.self) { _ in
                    Color.clear.frame(height: 60)
                }
                ForEach(daysInMonth(for: selectedDate), id: \.self) { day in
                    dayCellView(for: day)
                }
            }
            .padding(.top, 8)
        }
    }

    private func dayCellView(for day: Int) -> some View {
        VStack(spacing: 4) {
            Button(action: {
                selectedDay = day
            }) {
                VStack(spacing: 4) {
                    Text("\(day)")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(isToday(day) ? Color.blue.opacity(0.2) : Color.clear)
                        .foregroundColor(isToday(day) ? .blue : .primary)
                        .clipShape(Circle())

                    if let mood = moodStore.moodLogs[formattedDateKey(for: day)],
                       let emoji = moodEmojis[mood] {
                        Text(emoji).font(.title3)
                    } else if isPastDay(day) {
                        Image(systemName: "questionmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Spacer().frame(height: 20)
                    }
                }
                .frame(height: 60)
                .padding(6)
                .background(isSelectedDay(day) ? Color.teal.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func isToday(_ day: Int) -> Bool {
        let calendar = Calendar.current
        guard let date = calendar.date(bySetting: .day, value: day, of: selectedDate) else { return false }
        return calendar.isDateInToday(date)
    }

    private func isPastDay(_ day: Int) -> Bool {
        let calendar = Calendar.current
        guard let date = calendar.date(bySetting: .day, value: day, of: selectedDate) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }

    private func isSelectedDay(_ day: Int) -> Bool {
        selectedDay == day
    }

    private func daysInMonth(for date: Date) -> [Int] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: date) else { return [] }
        return Array(range)
    }

    private func formattedDateKey(for day: Int) -> String {
        var components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        components.day = day
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formattedMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func emptyDaysBeforeMonth(for date: Date) -> [Int] {
        let calendar = Calendar.current
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: firstDay)
        return Array(repeating: 0, count: weekday - 1)
    }

    private func daysOfWeekView() -> some View {
        HStack(spacing: 0) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(MoodStore())
    }
}
