import Foundation

class PricesViewModel {
    private var httpClient = HTTPClient()
    private var webSocketClient: WebSocketClient?
    private let defaultInstrumentId = "ebefe2c7-5ac9-43bb-a8b7-4a97bf2c2576"
    
    var accessToken: String?
    var instruments: [Instrument] = []
    var selectedInstrument: Instrument? {
        didSet {
            onInstrumentSelected?()
            fetchBars()
        }
    }
    
    var isSubscribed: Bool = false {
        didSet { onSubscriptionStatusChanged?(isSubscribed) }
    }
    
    var onInstrumentsReceived: (() -> Void)?
    var onDefaultInstrumentIndex: ((Int) -> Void?)?
    var onInstrumentSelected: (() -> Void)?
    var onPriceUpdated: ((String) -> Void)?
    var onTimeUpdated: ((String) -> Void)?
    var onBarsUpdated: (([Bar]) -> Void)?
    var onSubscriptionStatusChanged: ((Bool) -> Void)?

    // MARK: - Network Methods
    
    func getAccessToken() {
        Task {
            accessToken = try? await httpClient.getAccessToken()
            if let accessToken {
                connectWebSocket(token: accessToken)
                await getInstruments(token: accessToken)
            }
        }
    }
    
//    func getAccessToken() async {
//        accessToken = try? await httpClient.getAccessToken()
//        if let accessToken {
//            connectWebSocket(token: accessToken)
//            await getInstruments(token: accessToken)
//        }
//    }
    
    func getInstruments(token: String) async {
        let instruments = try? await httpClient.getInstruments(token)
        if let instruments {
            self.instruments = instruments
            setDefaultInstrument()
            onInstrumentsReceived?()
        }
    }
    
    private func fetchBars() {
        guard let accessToken, let selectedInstrumentId = selectedInstrument?.id else { return }

        Task.detached { [weak self] in
            let bars = try? await self?.httpClient.getBars(accessToken, selectedInstrumentId)
            if let bars {
                self?.onBarsUpdated?(bars)
            }
        }
    }

    private func setDefaultInstrument() {
        let defaultInstrumentIndex = instruments.firstIndex { $0.id == defaultInstrumentId }
        
        if let defaultInstrumentIndex {
            selectedInstrument = instruments[defaultInstrumentIndex]
            onDefaultInstrumentIndex?(defaultInstrumentIndex)
            // picker.selectRow(defaultInstrumentIndex, inComponent: 0, animated: false)
        }
        
        
        if let defaultInstrument = instruments.first(where: { $0.id == defaultInstrumentId }) {
            selectedInstrument = defaultInstrument
        }
    }

    // MARK: - WebSocket
    
    private func connectWebSocket(token: String) {
        webSocketClient = WebSocketClient(accessToken: token)
        webSocketClient?.connect()
        
        webSocketClient?.onMessageReceived = { [weak self] message in
            self?.handleWebSocketMessage(message)
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        guard isSubscribed else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        if let instrumentUpdate = try? decoder.decode(InstrumentUpdateDto.self, from: message.data(using: .utf8)!),
           let quotation = instrumentUpdate.ask ?? instrumentUpdate.bid {

            onPriceUpdated?("\(quotation.price)")
            onTimeUpdated?(formattedTime(from: quotation.timestamp))
        }
    }
    
    
    // todo: unsubscribe
    func toggleSubscription() {
        isSubscribed.toggle()
        sendSubscriptionMessage()
    }
    
    func unsubscribe() {
        if isSubscribed {
            isSubscribed = false
            sendSubscriptionMessage()
        }
    }
    
    private func sendSubscriptionMessage() {
        if let instrumentId = selectedInstrument?.id {
            let message = subscriptionMessage(instrumentId: instrumentId, subscribe: isSubscribed)
            if let jsonData = try? JSONEncoder().encode(message) {
                webSocketClient?.sendMessage(String(data: jsonData, encoding: .utf8)!)
            }
        }
    }
    
    private func subscriptionMessage(instrumentId: String, subscribe: Bool) -> SubscribeMessageDto {
        SubscribeMessageDto(type: "l1-subscription", id: "1", instrumentId: instrumentId, provider: "simulation", subscribe: subscribe, kinds: ["ask", "bid", "last"])
    }
    
    // MARK: - Helper
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
