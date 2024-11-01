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
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }

    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.onMessageReceived?(text)
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    print("Received unknown message")
                }

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
