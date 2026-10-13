import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var banner: Banner?

    struct Banner: Equatable {
        var text: String
        var isSuccess: Bool
    }

    private let backendURL = URL(string: "https://msg.calcs.top/api/feedback")!
    private let maxMessageLength = 1000

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".") && !email.hasPrefix("@")
    }

    private var canSubmit: Bool {
        let effectiveSubject = subject == "Other" ? customSubject.trimmingCharacters(in: .whitespaces) : subject
        return !effectiveSubject.isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailIsValid && !message.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    subjectGrid
                    if subject == "Other" {
                        TextField("Custom subject", text: $customSubject)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                    if !email.isEmpty && !emailIsValid {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .overlay(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("Tell us what's on your mind...")
                                        .foregroundStyle(.secondary.opacity(0.6))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                            .onChange(of: message) { _, newValue in
                                if newValue.count > maxMessageLength {
                                    message = String(newValue.prefix(maxMessageLength))
                                }
                            }
                        Text("\(message.count) / \(maxMessageLength)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    submitButton
                    Text("We only use your email to respond to this feedback.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(alignment: .top) {
                if let banner {
                    Text(banner.text)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(banner.isSuccess ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .transition(.move(edge: .top))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: banner)
        }
    }

    private var subjectGrid: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                subjectTile("General", icon: "bubble.left.fill")
                subjectTile("Feature Suggestion", icon: "lightbulb.fill")
                subjectTile("Bug Report", icon: "ant.fill")
                subjectTile("Usage Question", icon: "questionmark.circle.fill")
                subjectTile("Performance Issue", icon: "gauge.with.dots.needle.67percent")
                subjectTile("UI Improvement", icon: "paintpalette.fill")
            }
            subjectTile("Other", icon: "ellipsis.circle.fill")
        }
    }

    private func subjectTile(_ title: String, icon: String) -> some View {
        Button {
            subject = title
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(subject == title ? Color.amber.opacity(0.9) : Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(subject == title ? Color.amber : Color.separator, lineWidth: subject == title ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if subject == title {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tolex)
                        .padding(6)
                }
            }
            .foregroundStyle(subject == title ? Color.tolex : Color.primary)
            .scaleEffect(subject == title ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)\(subject == title ? ", selected" : "")")
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                Text("Submit")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSubmit)
    }

    private func submit() {
        isSubmitting = true
        let payload = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: subject == "Other" ? customSubject.trimmingCharacters(in: .whitespaces) : subject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "AmpWhisper"
        )
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                _ = data
                await MainActor.run {
                    isSubmitting = false
                    banner = Banner(text: "Thank you! Your feedback has been sent.", isSuccess: true)
                    clearForm()
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    banner = Banner(text: "Something went wrong. Please try again.", isSuccess: false)
                }
            }
        }
    }

    private func clearForm() {
        name = ""
        email = ""
        message = ""
        customSubject = ""
        subject = "General"
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

extension Color {
    static let separator = Color(uiColor: .separator)
}
