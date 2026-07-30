//
//  LoginView.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

// MARK: - Theme Colors (Tailwind Config Translation)
extension Color {
    static let themeBackground = Color(red: 13/255.0, green: 21/255.0, blue: 20/255.0)
    static let themePrimary = Color(red: 133/255.0, green: 255/255.0, blue: 241/255.0) // #85fff1
    static let themePrimaryVariant = Color(red: 0/255.0, green: 218/255.0, blue: 243/255.0) // #00daf3
    static let themeCard = Color(red: 47/255.0, green: 54/255.0, blue: 53/255.0) // #2f3635
    static let themeInput = Color(red: 13/255.0, green: 21/255.0, blue: 20/255.0) // #0d1514
    static let themeSurfaceContainer = Color(red: 26/255.0, green: 33/255.0, blue: 32/255.0) // #1a2120
    static let themeOnSurfaceVariant = Color(red: 186/255.0, green: 202/255.0, blue: 198/255.0) // #bacac6
    static let themeOnPrimary = Color(red: 0/255.0, green: 32/255.0, blue: 29/255.0) // #00201d
}

// MARK: - Focus State
enum FormField {
    case githubLink
    case accessKey
}

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.openURL) private var openURL
    
    // Form State
    @State private var githubLink: String = ""
    @State private var accessKey: String = ""
    @State private var showKey = false
    @State private var errorMessage: String?
    
    // UI State
    @State private var tiltX: Double = 0
    @State private var tiltY: Double = 0
    @FocusState private var focusedField: FormField?
    
    var body: some View {
        ZStack {
            background
            
            // Ambient glows
            ambientGlow(topLeading: true)
            ambientGlow(topLeading: false)
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer(minLength: 32)
                        
                        loginCard
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 24)
                    }
                    .frame(minHeight: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                        hideKeyboard()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            githubLink = session.savedEmail // Reused session variable or update SessionStore field
            accessKey = session.savedAccessKey ?? ""
        }
    }
}

// MARK: - Core UI Components
extension LoginView {
    
    private var loginCard: some View {
        VStack(spacing: 24) {
            headerSection
            
            VStack(spacing: 14) {
                inputField(
                    title: "Personal GitHub Link",
                    systemImage: "link",
                    placeholder: "https://github.com/username",
                    text: $githubLink,
                    isSecure: false,
                    keyboardType: .URL
                )
                .focused($focusedField, equals: .githubLink)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .accessKey
                }
                
                inputField(
                    title: "Personal Access Key",
                    systemImage: "key.fill",
                    placeholder: "ghp_••••••••••••••••••••",
                    text: $accessKey,
                    isSecure: !showKey
                ) {
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.50))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }
                .focused($focusedField, equals: .accessKey)
                .submitLabel(.done)
                .onSubmit {
                    signIn()
                }
                
                HStack {
                    Spacer()
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.themePrimary)
                }
                
                Button {
                    signIn()
                } label: {
                    HStack(spacing: 10) {
                        Text("Initialize Session")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.themeOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            footerSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.themeCard.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 4)
        .rotation3DEffect(.degrees(tiltX), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(tiltY), axis: (x: 1, y: 0, z: 0))
        .animation(.interpolatingSpring(stiffness: 150, damping: 12), value: tiltX)
        .animation(.interpolatingSpring(stiffness: 150, damping: 12), value: tiltY)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let x = Double(value.translation.width) / 50.0
                    let y = Double(value.translation.height) / 50.0
                    tiltX = max(-8, min(8, x))
                    tiltY = max(-8, min(8, -y))
                }
                .onEnded { _ in
                    tiltX = 0
                    tiltY = 0
                }
        )
    }
}

// MARK: - ViewBuilders & Helper Views
extension LoginView {
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.themeSurfaceContainer)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
                
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.themePrimary)
            }
            
            VStack(spacing: 4) {
                Text("GitGud")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.themePrimary)
                
                Text("Your GitHub, Reimagined.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color.themeOnSurfaceVariant)
            
            Button("Request Access") {
                if let url = URL(string: "https://github.com/signup") {
                    openURL(url)
                }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Color.themePrimary)
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.top, 4)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func inputField<TrailingContent: View>(
        title: String,
        systemImage: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        keyboardType: UIKeyboardType = .default,
        @ViewBuilder trailingButton: () -> TrailingContent = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.themeOnSurfaceVariant)
                .padding(.leading, 2)
            
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.50))
                    .frame(width: 20)
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: text)
                    } else {
                        TextField(placeholder, text: text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(keyboardType)
                    }
                }
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                
                trailingButton()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color.themeInput.opacity(0.6))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.themePrimaryVariant),
                alignment: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .contentShape(Rectangle())
    }
    
    private var background: some View {
        Color.themeBackground
            .ignoresSafeArea()
            .contentShape(Rectangle())
    }
    
    private func ambientGlow(topLeading: Bool) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.themePrimary.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
            .blur(radius: 6)
            .offset(
                x: topLeading ? -160 : 160,
                y: topLeading ? -240 : 260
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Validation & Actions
extension LoginView {
    private func signIn() {
        focusedField = nil
        
        let trimmedLink = githubLink.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedLink.isEmpty else {
            errorMessage = "Enter your personal GitHub link."
            return
        }
        
        guard isValidGitHubURL(trimmedLink) else {
            errorMessage = "Enter a valid GitHub profile URL\n(e.g., https://github.com/username)."
            return
        }
        
        guard !trimmedKey.isEmpty else {
            errorMessage = "Enter your personal access key."
            return
        }
        
        guard isValidGitHubToken(trimmedKey) else {
            errorMessage = "Invalid Access Key. It should start with 'ghp_' or 'github_pat_'."
            return
        }
        
        errorMessage = nil
        session.signIn(email: trimmedLink, accessKey: trimmedKey)
    }
    
    // MARK: Helpers
    
    /// Validates if a string is a properly formatted GitHub profile URL.
    private func isValidGitHubURL(_ urlString: String) -> Bool {
        // Matches https://github.com/username or github.com/username
        // GitHub usernames can be alphanumeric with single hyphens, max 39 chars.
        let pattern = "^(https?://)?(www\\.)?github\\.com/[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}/?$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex.firstMatch(in: urlString, options: [], range: range) != nil
    }
    
    /// Validates standard GitHub Personal Access Token formats.
    private func isValidGitHubToken(_ token: String) -> Bool {
        // Known GitHub prefixes for Classic, Fine-Grained, and other internal tokens.
        let validPrefixes = ["ghp_", "github_pat_", "gho_", "ghu_", "ghs_", "ghr_"]
        let hasValidPrefix = validPrefixes.contains(where: token.hasPrefix)
        
        // Ensure it has a valid prefix and minimum expected length (Classic tokens are 40 chars)
        return hasValidPrefix && token.count >= 40
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
