//
//  AllRepositoriesView.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct AllRepositoriesView: View {
    let username: String
    let pinnedRepos: [PinnedRepo]
    
    @Environment(\.dismiss) private var dismiss
    @State private var allRepos: [StandardRepo] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !pinnedRepos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pinned Repositories")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                
                                ForEach(pinnedRepos) { repo in
                                    PinnedRepoCard(repo: repo)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Repositories")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.cyan)
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else if allRepos.isEmpty {
                                Text("No repositories found.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(allRepos) { repo in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(repo.name)
                                            .font(.headline)
                                            .foregroundStyle(.cyan)
                                        
                                        if let description = repo.description {
                                            Text(description)
                                                .font(.subheadline)
                                                .foregroundStyle(.gray)
                                                .lineLimit(2)
                                        }
                                        
                                        if let language = repo.language {
                                            Text(language)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Repositories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(.cyan)
                }
            }
            .task {
                await fetchAllRepos()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func fetchAllRepos() async {
        let urlString = "https://api.github.com/users/\(username)/repos?sort=updated&per_page=100"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedRepos = try JSONDecoder().decode([StandardRepo].self, from: data)
            
            await MainActor.run {
                self.allRepos = decodedRepos
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch all repos: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
