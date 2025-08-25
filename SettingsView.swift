import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = true
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    @EnvironmentObject var moodStore: MoodStore

    @State private var username: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var showHelp = false
    @State private var showDeleteConfirm = false
    @State private var showClearDataConfirm = false
    @State private var showTerms = false
    @State private var selectedLanguage = "English"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    let languageOptions = ["English", "Spanish", "French", "German", "Chinese"]

    var body: some View {
        NavigationView {
            List {
                // Account Info
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(username.isEmpty ? "Not signed in" : username)
                            .foregroundColor(.gray)
                    }
                }

                // Appearance
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                // Preferences
                Section(header: Text("Preferences")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                    Picker("App Language", selection: $selectedLanguage) {
                        ForEach(languageOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                // Privacy Controls
                Section(header: Text("Privacy & Security")) {
                    Button("Clear Mood & Diary Data") {
                        showClearDataConfirm = true
                    }
                    .foregroundColor(.red)

                    Button("View Terms & Conditions") {
                        showTerms = true
                    }
                    .foregroundColor(.blue)
                }

                // Help
                Section {
                    Button("Help / How to Use") {
                        showHelp = true
                    }
                    .foregroundColor(.blue)
                }

                // Logout & Delete
                Section {
                    Button("Log Out") {
                        do {
                            try Auth.auth().signOut()
                            isLoggedIn = false
                        } catch {
                            errorMessage = "Log out failed: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                    .foregroundColor(.blue)

                    Button("Delete Account") {
                        showDeleteConfirm = true
                    }
                    .foregroundColor(.red)
                }

                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Muskan")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadUserData)
            .alert("Help Guide", isPresented: $showHelp) {
                Button("Close", role: .cancel) { }
            } message: {
                Text("Track moods, write journals, and view your emotional trends. All data is private and can be cleared anytime.")
            }
            .alert("Clear All Data?", isPresented: $showClearDataConfirm) {
                Button("Clear", role: .destructive) {
                    moodStore.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all mood and diary entries.")
            }
            .alert("Are you sure?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Deleting your account will remove all data permanently. This cannot be undone.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showTerms) {
                TermsAndConditionsView()
            }
        }
    }

    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            username = user.email ?? "User123"
        } else {
            username = ""
        }
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user found. Please sign in again."
            showErrorAlert = true
            return
        }

        user.delete { error in
            if let error = error {
                errorMessage = "Deletion failed. Please re-authenticate and try again. (\(error.localizedDescription))"
                showErrorAlert = true
            } else {
                moodStore.clearAllData()
                isLoggedIn = false
            }
        }
    }
}

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms & Conditions")
                    .font(.title.bold())

                Text("""
                Welcome to **Mood Journal**, a personal tool for self-reflection and emotional awareness. By using this app, you agree to the following Terms and Conditions. Please read them carefully:

                1. **Personal Wellness Use**  
                Mood Journal is intended to support your emotional self-care by allowing you to track your moods and thoughts. It is **not a substitute for professional mental health care**.

                2. **No Medical Advice**  
                Any mood insights are automatically generated and do not constitute medical advice or diagnosis.

                3. **Your Data, Your Privacy**  
                All data is stored **locally**. We do not collect or transmit your private information.

                4. **Your Responsibility**  
                Please keep your device secure with a password, Touch ID, or Face ID.

                5. **Account & Data Deletion**  
                You can delete your account and data any time. Once deleted, it cannot be restored.

                6. **Updates to Terms**  
                Continued use after updates means you agree to the new terms.

                Thank you for choosing Mood Journal.
                """)
                    .font(.body)
                    .padding(.bottom, 30)
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(MoodStore())
    }
}
