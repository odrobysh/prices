import Foundation
struct AccessTokenDto: Decodable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct SubscribeMessageDto: Encodable {
    let type: String
    let id: String
    let instrumentId: String
    let provider: String
    let subscribe: Bool
    let kinds: [String]
}

public struct WebSocket {
    let webSocketTask: URLSessionWebSocketTask
    func listen() {
        webSocketTask.receive { result in
            print("received some message")
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
            case .success(let message):
                
                print("Received message: \(message)")
                switch message {
                case .string(let text):
                    print("Received text message: \(text)")
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    fatalError()
                }
                
                self.listen()
            }
        }
    }
    
    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
            }
        }
    }
    
    func ping() {
        webSocketTask.sendPing { (error) in
            if let error = error {
                print("Ping failed: \(error)")
            }
            else {
                print("ping")
            }
            self.scheduleNextPing()
        }
    }
    
    func scheduleNextPing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ping()
        }
    }
    
    init(_ token: String) {
        webSocketTask = URLSession.shared.webSocketTask(with: URL(
            string: "wss://platform.fintacharts.com/api/streaming/ws/v1/realtime?token=\(token)")!
        )
        
        webSocketTask.resume()
    }
}

public struct Net {
   
    static var getAccessToken: () async throws -> String = {
        let uri = "https://platform.fintacharts.com"
        let url = URL(string: "\(uri)/identity/realms/fintatech/protocol/openid-connect/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            .init(name: "grant_type", value: "password"),
            .init(name: "client_id", value: "app-cli"),
            .init(name: "username", value: "r_test@fintatech.com"),
            .init(name: "password", value: "kisfiz-vUnvy9-sopnyv")
        ]
        
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let fetchedData = try JSONDecoder().decode(AccessTokenDto.self, from: data)
        return fetchedData.accessToken
    }
}

