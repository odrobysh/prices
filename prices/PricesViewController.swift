import UIKit

extension PricesViewController {
    @MainActor func setAccessToken(_ token: String) {
        accessToken = token
    }
    
    @MainActor func setInstruments(_ newInstruments: [Instrument]) {
        instruments = newInstruments
    }
}

class PricesViewController: UIViewController {

    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var time: UILabel!
    
    var webSocketClient: WebSocketClient?
    var accessToken: String? {
        didSet {
            if let accessToken {
                getInstruments(token: accessToken)
            }
        }
    }
    
    var instruments: [Instrument] = [] {
        didSet {
            displayInstrument()
        }
    }
    
    private func displayInstrument() {
        if let selectedInstrument = instruments.first {
            input.text = selectedInstrument.description
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        // Mock
        input.text = "BTC/USD"
        symbol.text = "Symbol\nBTC/USD"
        price.text = "Price\n$48.126,333"
        time.text = "Time\nAug 7, 9:45 AM"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    private func getInstruments(token: String) {
        Task.detached { [weak self] in
            let instruments = try? await Net.getInstruments(token)
            if let instruments {
                print("we have instruments")
                await self?.setInstruments(instruments)
            }
        }
    }

    @IBAction func subscribe() {
        print("subscribe")
        
        webSocketClient = WebSocketClient(accessToken: accessToken!)
        webSocketClient?.connect()
        
        let message = SubscribeMessageDto(type: "l1-subscription", id: "1", instrumentId: "ad9e5345-4c3b-41fc-9437-1d253f62db52", provider: "simulation", subscribe: true, kinds: ["ask", "bid", "last"])
        
        if let jsonData = try? JSONEncoder().encode(message) {
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            webSocketClient?.sendMessage(jsonString)
        }
        
        
    }
    
}

