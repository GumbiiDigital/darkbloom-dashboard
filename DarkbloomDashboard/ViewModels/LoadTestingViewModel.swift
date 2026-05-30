import Foundation
import OpenAI

@MainActor @Observable
final class LoadTestingViewModel {
    private(set) var inProgress: Bool = false
    
    private(set) var requestsDone: Int = 0
    private(set) var requestsInFlight: Int = 0
    private(set) var requestsFailed: Int = 0
    
    var requestsToSend: Int = 20
    var responses: [ChatResult] = []
    
    init() {}
    
    func run(apiKey: String) async throws {
        guard !inProgress else { return }
        
        inProgress = true
        defer { inProgress = false }
        
        let config = OpenAI.Configuration(
            token: apiKey,
            host: "api.darkbloom.dev",
            scheme: "https",
            basePath: "/v1",
            parsingOptions: .relaxed
        )
        
        await withTaskGroup(of: ChatResult?.self) { group in
            for i in 0..<requestsToSend {
                group.addTask {
                    try? await Task.sleep(for: .seconds(i * 2))
                    let client = OpenAI(configuration: config)
                    let query = ChatQuery(messages: [
                        .user(.init(content: .string("Hello! Response in one word.")))
                    ], model: "gpt-oss-20b")
                    await MainActor.run {
                        self.requestsInFlight += 1
                    }
                    do {
                        return try await client.chats(query: query)
                    } catch {
                        print(error)
                        return nil
                    }
                }
            }
            
            for await response in group {
                await MainActor.run {
                    self.requestsInFlight -= 1
                    if let response {
                        self.requestsDone += 1
                        self.responses.append(response)
                    } else {
                        self.requestsFailed += 1
                    }
                }
            }
        }
    }
}
