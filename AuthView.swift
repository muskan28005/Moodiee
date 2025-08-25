import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignup = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("SoftBlue"), Color("SoftGreen")]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text(isSignup ? "Create Account" : "Welcome Back")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(isSignup ? "Let’s get you started." : "Sign in to continue your journey.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    if isSignup {
                        InputField(label: "Full Name", placeholder: "Jane Doe", text: $name)
                    }

                    InputField(label: "Email", placeholder: "you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    PasswordField(password: $password)
                }

                if !isSignup {
                    Button("Forgot Password?") {
                        sendPasswordReset()
                    }
                    .font(.footnote)
                    .foregroundColor(Color.blue.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, -8)
                }

                Button(action: handleAuthAction) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isSignup ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
                .disabled(isProcessing)

                Button(action: {
                    withAnimation { isSignup.toggle() }
                }) {
                    Text(isSignup ? "Already have an account? Sign In" : "New here? Create Account")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
            .shadow(color: .gray.opacity(0.15), radius: 10, x: 0, y: 4)
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Oops"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func handleAuthAction() {
        errorMessage = ""
        isProcessing = true

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true
            isProcessing = false
            return
        }

        if isSignup {
            guard !name.isEmpty else {
                errorMessage = "Please enter your name."
                showAlert = true
                isProcessing = false
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error as NSError? {
                    self.errorMessage = friendlyAuthErrorMessage(error)
                    self.showAlert = true
                    self.isProcessing = false
                    return
                }

                if let user = result?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = self.name
                    changeRequest.commitChanges { _ in
                        user.sendEmailVerification { error in
                            self.errorMessage = error != nil
                                ? "Couldn't send verification email. Try again later."
                                : "Verification email sent. Please check your inbox."
                            self.showAlert = true
                            self.isProcessing = false
                        }
                    }
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error as NSError? {
                    self.errorMessage = friendlyAuthErrorMessage(error)
                    self.showAlert = true
                    self.isProcessing = false
                    return
                }

                if let user = result?.user {
                    if user.isEmailVerified {
                        self.isLoggedIn = true
                    } else {
                        self.errorMessage = "Please verify your email before signing in."
                        self.showAlert = true
                    }
                }
                self.isProcessing = false
            }
        }
    }

    private func sendPasswordReset() {
        guard !email.isEmpty else {
            errorMessage = "Enter your email to receive reset instructions."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error as NSError? {
                self.errorMessage = friendlyAuthErrorMessage(error)
            } else {
                self.errorMessage = "Password reset link sent. Check your inbox."
            }
            self.showAlert = true
        }
    }

    private func friendlyAuthErrorMessage(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "That email doesn’t look right. Please check and try again."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Try again or tap 'Forgot Password?'."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found for this email. Try signing up first."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "That email is already registered. Try signing in instead."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password too weak. Use at least 6 characters."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}

// MARK: - Subviews

struct InputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct PasswordField: View {
    @Binding var password: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password")
                .font(.caption)
                .foregroundColor(.secondary)
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Preview
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(isLoggedIn: .constant(false))
    }
}
