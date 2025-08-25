import SwiftUI

struct ContentView: View {
    @EnvironmentObject var moodStore: MoodStore

    @State private var selectedEmotion: String? = nil
    @State private var savedEmotion: String? = nil
    @State private var selectedDate = Date()
    @State private var showSavedMessage = false

    let emotions = [
        ("Delighted", "😁"),
        ("Happy", "😊"),
        ("Neutral", "😐"),
        ("Sad", "😞"),
        ("Awful", "😖")
    ]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header + Notification
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Hello! 🌟")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            Text("How are you feeling today?")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        NavigationLink(destination: NotificationsView()) {
                            Image(systemName: "bell.badge")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)

                    // Date Picker
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today is")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(formattedDate(selectedDate))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .tint(.white)
                            .onChange(of: selectedDate) { _ in loadMoodLog() }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Mood Grid
                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(emotions, id: \.0) { emotion in
                            VStack(spacing: 8) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        selectedEmotion = emotion.0
                                    }
                                }) {
                                    Text(emotion.1)
                                        .font(.system(size: 50))
                                        .frame(width: 80, height: 80)
                                        .background(selectedEmotion == emotion.0 ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(selectedEmotion == emotion.0 ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(color: .white.opacity(selectedEmotion == emotion.0 ? 0.6 : 0), radius: 8, x: 0, y: 5)
                                }
                                Text(emotion.0)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Save Mood Button
                    if selectedEmotion != nil && selectedEmotion != savedEmotion {
                        Button(action: saveMoodLog) {
                            Text("Save Mood")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(20)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .shadow(radius: 8)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.4), value: selectedEmotion)
                    }

                    // Journal Link
                    NavigationLink(destination: DiaryEntryView(date: selectedDate)) {
                        Text("Write a Journal ✍️")
                            .font(.subheadline.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                    .padding([.horizontal, .bottom])
                }

                // Toast
                if showSavedMessage {
                    VStack {
                        Spacer()
                        Text("Mood Saved! ✅")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(radius: 10)
                            .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadMoodLog)
        }
    }

    private func saveMoodLog() {
        moodStore.saveMood(for: selectedDate, mood: selectedEmotion ?? "?")
        savedEmotion = selectedEmotion

        withAnimation {
            showSavedMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedMessage = false
            }
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func loadMoodLog() {
        selectedEmotion = moodStore.getMood(for: selectedDate)
        savedEmotion = selectedEmotion
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
                .environmentObject(MoodStore())
        }
    }
}
