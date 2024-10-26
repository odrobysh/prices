import Foundation

class WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private let webSocketURL = "wss://platform.fintacharts.com/api/streaming/ws/v1/realtime?token="
    private let accessToken: String
    var onMessageReceived: ((String) -> Void)?

    init(accessToken: String) {
        self.accessToken = accessToken
        self.urlSession = URLSession(configuration: .default)
    }

    func connect() {
        let request = URLRequest(url: URL(string: "\(webSocketURL)\(accessToken)")!)
        
        // Initialize the WebSocket task
        webSocketTask = urlSession.webSocketTask(with: request)
        
        // Start the WebSocket connection
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
    }

    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    self?.onMessageReceived?(text)
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    print("Received unknown message")
                }
                // Continue listening for more messages
                self?.receiveMessage()

            case .failure(let error):
                print("Error receiving message: \(error)")
            }
        }
    }

    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// Usage:
//
//let webSocketURL = URL(string: "wss://your-websocket-server.com")!
//let authToken = "your-auth-token"
//
//let client = WebSocketClient(url: webSocketURL, authToken: authToken)
//client.connect()
//
//// Send a message after connecting
//client.sendMessage("Hello WebSocket!")
//
//// Close the connection when done
//client.disconnect()
