import SwiftUI
import Charts

struct MonthlyMoodData: Identifiable {
    let id: Date
    let month: Date
    let counts: [String: Int]
}

struct MonthlyAverageMood: Identifiable {
    let id: Date
    let month: Date
    let average: Double
}

struct StatsView: View {
    @EnvironmentObject var moodStore: MoodStore
    
    @State private var selectedDate: Date = Date()
    @State private var graphSelectedDate: Date = Date()
    
    private var monthlyMoodCounts: [String: [String: Int]] {
        var counts: [String: [String: Int]] = [:]
        for (dateString, mood) in moodStore.moodLogs {
            if let date = formattedDateToDate(dateString) {
                let monthYear = formattedMonthYear(date)
                if counts[monthYear] == nil {
                    counts[monthYear] = ["Delighted": 0, "Happy": 0, "Neutral": 0, "Sad": 0, "Awful": 0]
                }
                counts[monthYear]?[mood, default: 0] += 1
            }
        }
        return counts
    }
    
    private var sortedMonthlyData: [MonthlyMoodData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let data = monthlyMoodCounts.compactMap { (key, counts) -> MonthlyMoodData? in
            if let date = formatter.date(from: key) {
                return MonthlyMoodData(id: date, month: date, counts: counts)
            }
            return nil
        }
        return data.sorted { $0.month < $1.month }
    }
    
    private var monthlyAverageMoods: [MonthlyAverageMood] {
        let moodValue: [String: Int] = ["Awful": 1, "Sad": 2, "Neutral": 3, "Happy": 4, "Delighted": 5]
        return sortedMonthlyData.compactMap { monthlyData in
            let totalCount = monthlyData.counts.values.reduce(0, +)
            guard totalCount > 0 else { return nil }
            let totalScore = monthlyData.counts.reduce(0) { result, pair in
                let mood = pair.key
                let count = pair.value
                let value = moodValue[mood] ?? 3
                return result + (value * count)
            }
            let avg = Double(totalScore) / Double(totalCount)
            return MonthlyAverageMood(id: monthlyData.month, month: monthlyData.month, average: avg)
        }
    }
    
    private var filteredGraphData: [MonthlyAverageMood] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -5, to: graphSelectedDate) ?? graphSelectedDate
        return monthlyAverageMoods.filter { $0.month >= startDate && $0.month <= graphSelectedDate }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                monthSelectorView
                barChartView
                Divider().padding(.vertical)
                trendHeaderView
                graphNavigationView
                moodLineChartView
                if let latest = filteredGraphData.last {
                    Text(String(format: "Latest Average Mood: %.2f", latest.average))
                        .padding()
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var monthSelectorView: some View {
        HStack {
            Button {
                if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                    selectedDate = newDate
                }
            } label: {
                Image(systemName: "chevron.left").font(.title)
            }

            Spacer()
            Text(formattedMonthYear(selectedDate)).font(.title2)
            Spacer()

            Button {
                if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                    selectedDate = newDate
                }
            } label: {
                Image(systemName: "chevron.right").font(.title)
            }
        }
        .padding()
    }

    private var barChartView: some View {
        HStack(alignment: .bottom, spacing: 24) {
            ForEach(["Delighted", "Happy", "Neutral", "Sad", "Awful"], id: \.self) { mood in
                let count = monthlyMoodCounts[formattedMonthYear(selectedDate)]?[mood] ?? 0

                VStack(spacing: 6) {
                    // Always show a minimal bar for zero counts
                    Rectangle()
                        .fill(moodColor(for: mood))
                        .frame(width: 30, height: max(CGFloat(count * 15), 8))
                        .cornerRadius(6)

                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.primary)

                    Text(mood)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var trendHeaderView: some View {
        Text("Monthly Average Mood Trend")
            .font(.title2)
            .padding(.bottom, 5)
    }

    private var graphNavigationView: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: graphSelectedDate) {
                        graphSelectedDate = newDate
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.title2)
                }

                Spacer()
                Text("Graph Ending: \(formattedMonthYear(graphSelectedDate))").font(.headline)
                Spacer()

                Button {
                    if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: graphSelectedDate) {
                        graphSelectedDate = newDate
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.title2)
                }
            }

            let startDate = Calendar.current.date(byAdding: .month, value: -5, to: graphSelectedDate) ?? graphSelectedDate
            Text("Graph Range: \(formattedMonthYear(startDate)) - \(formattedMonthYear(graphSelectedDate))")
                .font(.caption)
                .padding(.bottom, 5)
        }
        .padding(.horizontal)
    }

    private var moodLineChartView: some View {
        Chart {
            ForEach(filteredGraphData) { dataPoint in
                LineMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Average Mood", dataPoint.average)
                )
                .symbol(Circle())
                .foregroundStyle(.purple)
            }
        }
        .chartYScale(domain: 1...5)
        .frame(height: 300)
        .padding()
    }

    private func formattedMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formattedDateToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func moodColor(for mood: String) -> Color {
        switch mood {
        case "Delighted": return .yellow
        case "Happy": return .green
        case "Neutral": return .gray
        case "Sad": return .blue
        case "Awful": return .red
        default: return .black
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatsView()
                .environmentObject(MoodStore())
        }
    }
}
