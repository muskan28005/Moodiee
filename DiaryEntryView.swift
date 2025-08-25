import SwiftUI
import NaturalLanguage

struct DiaryEntryView: View {
    @EnvironmentObject var moodStore: MoodStore

    var date: Date
    @State private var selectedDate: Date
    @State private var diaryText: String = ""
    @State private var moodAnalysisResult: String = "📝 Start writing to analyze your mood."
    @State private var showSaveToast: Bool = false

    init(date: Date) {
        self.date = date
        _selectedDate = State(initialValue: date)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("How are you feeling today?")
                        .font(.largeTitle.bold())
                        .padding(.horizontal)

                    HStack {
                        Text("Date: \(formattedDate(selectedDate))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        if diaryText.isEmpty {
                            Text("Write your thoughts here...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }

                        TextEditor(text: $diaryText)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .frame(minHeight: 350)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 18) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                analyzeMood(diaryEntry: diaryText)
                            }
                        }) {
                            HStack {
                                Image(systemName: "face.smiling")
                                Text("Analyse Mood")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(action: {
                            withAnimation { saveEntry() }
                        }) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Save Entry")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        Text(moodAnalysisResult)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }

            if showSaveToast {
                VStack {
                    Spacer()
                    Text("✅ Entry Saved!")
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSaveToast)
                }
                .zIndex(1)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Diary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadEntry)
    }

    private func analyzeMood(diaryEntry: String) {
        let cleanEntry = diaryEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEntry.isEmpty else {
            moodAnalysisResult = "✍️ Please write something first."
            return
        }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = cleanEntry

        tagger.enumerateTags(in: cleanEntry.startIndex..<cleanEntry.endIndex,
                             unit: .paragraph,
                             scheme: .sentimentScore,
                             options: []) { tag, _ in
            if let sentiment = tag, let score = Double(sentiment.rawValue) {
                let mood: String
                let emoji: String

                switch score {
                case ..<(-0.25): mood = "Sad"; emoji = "😢"
                case -0.25..<0.25: mood = "Neutral"; emoji = "😐"
                case 0.25...: mood = "Happy"; emoji = "😊"
                default: mood = "Unclear"; emoji = "🤔"
                }

                // Show result but DO NOT save to mood log anymore
                moodAnalysisResult = "\(emoji) Your mood is: \(mood)"
            } else {
                moodAnalysisResult = "🤔 Could not analyze sentiment."
            }
            return false
        }
    }

    private func saveEntry() {
        moodStore.saveDiary(for: selectedDate, text: diaryText)

        showSaveToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveToast = false
            }
        }
    }

    private func loadEntry() {
        diaryText = moodStore.getDiary(for: selectedDate) ?? ""
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct DiaryEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiaryEntryView(date: Date())
                .environmentObject(MoodStore())
        }
    }
}
