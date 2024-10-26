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
    @IBOutlet weak var subscribeButton: UIButton!
    
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
        }
        
        
    }
    
    private func displayIsSubscribed() {
        subscribeButton.setTitle(subscribed ? "Unsubscribe" : "Subscribe", for: .normal)
        
//        if subscribed {
//            
//            symbol.text = "Symbol\n\(selectedInstrument?.symbol ?? "")"
//        } else {
//            symbol.text = "Symbol\n--"
//            price.text = "Price\n--"
//            time.text = "Time\n--"
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // view.backgroundColor = .red
        
//        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
//        view.addGestureRecognizer(recognizer)
        
        input.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.inputTap(_:))))
        
        
        // Mock
        input.text = "BTC/USD"
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
    
    private func getInstruments(token: String) {
        Task.detached { [weak self] in
            let instruments = try? await Net.getInstruments(token)
            if let instruments {
                print("we have instruments")
                await self?.setInstruments(instruments)
            }
        }
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
        print("Message received in ViewController: \(message)")
        
        guard let instrumentUpdate = try? JSONDecoder().decode(InstrumentUpdateDto.self, from: Data(message.utf8)),
              let quotation = instrumentUpdate.ask ?? instrumentUpdate.bid
        else {
            return
        }
        
        DispatchQueue.main.async { () -> Void in
            // call API here
            self.price.text = "Price\n\(quotation.price)"
            self.time.text = "Time\n\(quotation.timestamp)"
        }
        
        
        
        //time.text = "Time\nAug 7, 9:45 AM"
        
        
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
 
        
        
        
        // mock
        
        //        let actionClosure = { (action: UIAction) in
        //            print(action.title)
        //        }
        //        var menu: [UIMenuElement] = []
        //        for instrument in instruments {
        //            menu.append(UIAction(title: instrument.description, handler: actionClosure))
        //        }
        //
        //        subscribeButton.menu = UIMenu(options: .displayInline, children: menu)
        //
        //        subscribeButton.showsMenuAsPrimaryAction = true
        //        subscribeButton.changesSelectionAsPrimaryAction = true
    }
}

