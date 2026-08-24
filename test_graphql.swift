import Foundation

struct GraphQLReviewThreadsResponse: Codable {
    let data: DataContainer?

    struct DataContainer: Codable {
        let repository: Repository?

        struct Repository: Codable {
            let pullRequest: PullRequest?

            struct PullRequest: Codable {
                let reviewThreads: ReviewThreads?

                struct ReviewThreads: Codable {
                    let nodes: [Thread]?

                    struct Thread: Codable {
                        let id: String
                        let isResolved: Bool
                        let comments: Comments?

                        struct Comments: Codable {
                            let nodes: [Comment]?

                            struct Comment: Codable {
                                let databaseId: Int?
                                let body: String
                                let path: String?
                                let line: Int?
                                let startLine: Int?
                                let side: String?
                                let startSide: String?
                                let diffHunk: String?
                                let position: Int?
                                let originalPosition: Int?
                                let commit: Commit?
                                let originalCommit: Commit?
                                let createdAt: String
                                let updatedAt: String
                                let url: String
                                let replyTo: ReplyTo?
                                let author: Author?

                                struct Commit: Codable {
                                    let oid: String
                                }

                                struct ReplyTo: Codable {
                                    let databaseId: Int?
                                }

                                struct Author: Codable {
                                    let login: String
                                    let avatarUrl: String
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

let query = """
{
  repository(owner: "apple", name: "swift") {
    pullRequest(number: 1) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 100) {
            nodes {
              databaseId
              body
              path
              line
              startLine
              side
              startSide
              diffHunk
              position
              originalPosition
              commit {
                oid
              }
              originalCommit {
                oid
              }
              createdAt
              updatedAt
              url
              replyTo {
                databaseId
              }
              author {
                login
                avatarUrl
              }
            }
          }
        }
      }
    }
  }
}
"""

let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? ""

func executeGraphQL(query: String, token: String) async throws -> Data {
    guard let url = URL(string: "https://api.github.com/graphql") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    if !token.isEmpty {
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["query": query]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        let stringData = String(data: data, encoding: .utf8) ?? ""
        print("Error: HTTP \(String(describing: (response as? HTTPURLResponse)?.statusCode))\n\(stringData)")
        throw URLError(.badServerResponse)
    }
    return data
}

Task {
    do {
        let data = try await executeGraphQL(query: query, token: token)
        let stringData = String(data: data, encoding: .utf8) ?? ""

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(GraphQLReviewThreadsResponse.self, from: data)
            print("Successfully decoded!")
        } catch {
            print("Decoding error: \(error)")
            print("Raw response: \(stringData.prefix(1000))")
        }

    } catch {
        print("Failed to execute: \(error)")
    }
    exit(0)
}

RunLoop.main.run()
