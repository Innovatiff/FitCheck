import SwiftUI
import FirebaseAuth

struct UsernameSelectionView: View {
    let firebaseUser: User

    @EnvironmentObject private var authVM: AuthViewModel
    @State private var username = ""
    @State private var isChecking = false

    private var formatError: String? { UsernameValidator.errorMessage(for: username) }

    private var canSubmit: Bool {
        formatError == nil && !username.isEmpty && !isChecking
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Pick a username")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("This is how others will find you.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("@")
                        .foregroundStyle(.secondary)
                        .font(.title3)

                    TextField("username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.title3)
                        .onChange(of: username) { _, new in
                            if new.count > UsernameValidator.maxLength {
                                username = String(new.prefix(UsernameValidator.maxLength))
                            }
                            if authVM.error != nil { authVM.error = nil }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let msg = formatError ?? authVM.error {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                Task {
                    isChecking = true
                    await authVM.submitUsername(username, for: firebaseUser)
                    isChecking = false
                }
            } label: {
                ZStack {
                    Text("Continue")
                        .font(.headline)
                        .opacity(isChecking ? 0 : 1)
                    if isChecking {
                        ProgressView().tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? Color.accentColor : Color.accentColor.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSubmit)
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}
