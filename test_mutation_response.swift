import Foundation

let json = """
{
  "data": {
    "resolveReviewThread": {
      "thread": {
        "id": "123",
        "isResolved": true
      }
    }
  }
}
"""

struct GraphQLReviewThreadMutationResponse: Codable {
    let data: DataContainer?

    struct DataContainer: Codable {
        let thread: Thread?
        let resolveReviewThread: Payload?
        let unresolveReviewThread: Payload?

        struct Payload: Codable {
            let thread: Thread?
        }

        struct Thread: Codable {
            let id: String
            let isResolved: Bool
        }
    }
}

do {
    let response = try JSONDecoder().decode(GraphQLReviewThreadMutationResponse.self, from: json.data(using: .utf8)!)
    print(response.data?.resolveReviewThread?.thread?.isResolved)
} catch {
    print(error)
}
