import UIKit

class PricesViewController: UIViewController {
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var chartView: ChartView!
    
    //mock
    var count = 0
    var subscribed = false {
        didSet {
            displayIsSubscribed()
        }
    }
    
    var webSocketClient: WebSocketClient?
    var accessToken: String? {
        didSet {
            if let accessToken {
                connectWebSocket(token: accessToken)
                getInstruments(token: accessToken)
            }
        }
    }
    
    var instruments: [Instrument] = [] {
        didSet {
            displayDefaultInstrument()
        }
    }
    
    var selectedInstrument: Instrument? {
        didSet {
            displaySelectedInstrument()
        }
    }
    
    private func displayDefaultInstrument() {
        if let defaultInstrument = instruments.first {
            selectedInstrument = defaultInstrument
        }
    }
    
    private func displaySelectedInstrument() {
        if let selectedInstrument {
            input.text = selectedInstrument.description
            subscribeButton.isEnabled = true
            symbol.text = "Symbol\n\(selectedInstrument.symbol)"
            price.text = "Price\n--"
            time.text = "Time\n--"
        }
        
        getBars()
    }
    
    
    
    private func displayIsSubscribed() {
        subscribeButton.setTitle(subscribed ? "Unsubscribe" : "Subscribe", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        input.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.inputTap(_:))))
        
        symbol.text = "Symbol\n--"
        price.text = "Price\n--"
        time.text = "Time\n--"
    }
    
    @objc func inputTap(_ sender: UITapGestureRecognizer) {
        print("inputTap")
        
        // mock
        if count > instruments.count - 1 {
            count = 0
        } else {
            count = count + 1
        }
        
        selectedInstrument = instruments[count]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribed = false
        subscribeButton.isEnabled = false
        getAccessToken()
    }
    
    private func getAccessToken() {
        Task.detached { [weak self] in
            let token = try? await Net.getAccessToken()
            if let token {
                print("we have token")
                await self?.setAccessToken(token)
            }
        }
    }
    
    @MainActor func setAccessToken(_ token: String) {
        accessToken = token
    }
    
    private func getInstruments(token: String) {
        Task.detached { [weak self] in
            let instruments = try? await Net.getInstruments(token)
            if let instruments {
                print("we have instruments")
                await self?.setInstruments(instruments)
            }
        }
    }
    
    @MainActor func setInstruments(_ newInstruments: [Instrument]) {
        instruments = newInstruments
    }
    
    private func getBars() {
        guard let accessToken, let selectedInstrumentId = selectedInstrument?.id else { return }
        
        Task.detached { [weak self] in
            let bars = try? await Net.getBars(accessToken, selectedInstrumentId)
            if let bars {
                print("we have \(bars.count) bars")
                await self?.setBars(bars)
            }
        }
    }
    
    @MainActor func setBars(_ bars: [Bar]) {
        chartView.updateChart(bars)
    }
    
    func connectWebSocket(token: String) {
        if webSocketClient == nil {
            webSocketClient = WebSocketClient(accessToken: token)
            webSocketClient?.connect()
            
            webSocketClient?.onMessageReceived = { [weak self] message in
                self?.handleMessage(message)
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        guard let instrumentUpdate = try? decoder.decode(InstrumentUpdateDto.self, from: message.data(using: .utf8)!) else { return }
        
        guard let quotation = instrumentUpdate.ask ?? instrumentUpdate.bid else { return }
        
        DispatchQueue.main.async { () -> Void in
            self.price.text = "Price\n\(quotation.price)"
            self.time.text = "Time\n\(self.formattedTime(from: quotation.timestamp))"
        }
    }
    
    private func formattedTime(from date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    
    @IBAction func subscribe() {
        print("subscribe")
        
        guard let instrumentId = selectedInstrument?.id else { return }
        
        let message = SubscribeMessageDto(type: "l1-subscription", id: "1", instrumentId: instrumentId, provider: "simulation", subscribe: !subscribed, kinds: ["ask", "bid", "last"])
        
        if let jsonData = try? JSONEncoder().encode(message) {
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            webSocketClient?.sendMessage(jsonString)
            subscribed.toggle()
        }
    }
}

