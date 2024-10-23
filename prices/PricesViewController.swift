import UIKit

class PricesViewController: UIViewController {

    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var time: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .red
        
        input.text = "BTC/USD"
        symbol.text = "Symbol\nBTC/USD"
        price.text = "Price\n$48.126,333"
        time.text = "Time\nAug 7, 9:45 AM"
    }

    @IBAction func subscribe() {
        print("subscribe")
    }
    
}

