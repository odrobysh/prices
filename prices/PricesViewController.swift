import UIKit

extension PricesViewController {
    @MainActor func setAccessToken(_ token: String) {
        accessToken = token
    }
}

class PricesViewController: UIViewController {

    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var time: UILabel!
    
    var webSocketClient: WebSocketClient?
    var accessToken: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .red
        
        input.text = "BTC/USD"
        symbol.text = "Symbol\nBTC/USD"
        price.text = "Price\n$48.126,333"
        time.text = "Time\nAug 7, 9:45 AM"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task.detached { [weak self] in
            let token = try? await Net.getAccessToken()
            if let token {
                await self?.setAccessToken(token)
            }
//            setAccessToken(<#T##token: String##String#>)
//            self?.accessToken = try? await Net.getAccessToken()
            
//            guard let token else {
//                print("error getting token")
//                return
//            }
            
      
           // ws.receiveMessage()
            
            //print(token)
            
//            let ws = WebSocket(token)
//            ws.listen()
//            ws.ping()
        
            // let urlSession = URLSession.shared//(configuration: .default)
//            let webSocketTask = urlSession.webSocketTask(
//                with: URL(string: "wss://platform.fintacharts.com/api/streaming/ws/v1/realtime?token=\(token)")!
//            )
//            webSocketTask.resume()
//            
//            webSocketTask.receive { result in
//                switch result {
//                case .failure(let error):
//                    print("Failed to receive message: \(error)")
//                case .success(let message):
//                    switch message {
//                    case .string(let text):
//                        print("Received text message: \(text)")
//                    case .data(let data):
//                        print("Received binary message: \(data)")
//                    @unknown default:
//                        fatalError()
//                    }
//                }
//            }
        }
    }
    
//    func listen() {
//        webSocketTask.receive { [weak self] result in
//            switch result {
//            case .failure(let error):
//                print("Failed to receive message: \(error)")
//            case .success(let message):
//                switch message {
//                case .string(let text):
//                    print("Received text message: \(text)")
//                case .data(let data):
//                    print("Received binary message: \(data)")
//                @unknown default:
//                    fatalError()
//                }
//                
//                self.listen()
//            }
//        }
//    }

    @IBAction func subscribe() {
        print("subscribe")
        
        webSocketClient = WebSocketClient(accessToken: accessToken!)
        webSocketClient?.connect()
        
        let message = SubscribeMessageDto(type: "l1-subscription", id: "1", instrumentId: "ad9e5345-4c3b-41fc-9437-1d253f62db52", provider: "simulation", subscribe: true, kinds: ["ask", "bid", "last"])
        
        if let jsonData = try? JSONEncoder().encode(message) {
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            //let stringMessage = guard let jsonData = try? JSONEncoder().encode(model) else {
            
            webSocketClient?.sendMessage(jsonString)
        }
        
        
    }
    
}

