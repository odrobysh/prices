import UIKit

class PricesViewController: UIViewController {
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var chartView: ChartView!
    @IBOutlet weak var marketDataStack: UIStackView!
    let picker = UIPickerView()
    let emptyValue = "--"
    
    private let viewModel = PricesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.getAccessToken()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupViews()
    }
    
    @IBAction func subscribeButtonTap() {
        viewModel.toggleSubscription()
    }
    
    private func setupBindings() {
        viewModel.onInstrumentsReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.picker.reloadAllComponents()
            }
        }
        
        viewModel.onInstrumentSelected = { [weak self] in
            DispatchQueue.main.async {
                self?.displaySelectedInstrument()
            }
        }
        
        viewModel.onPriceUpdated = { [weak self] price in
            DispatchQueue.main.async {
                self?.displayPrice(price)
            }
        }
        
        viewModel.onTimeUpdated = { [weak self] time in
            DispatchQueue.main.async {
                self?.displayTime(time)
            }
        }
        
        viewModel.onBarsUpdated = { [weak self] bars in
            DispatchQueue.main.async {
                self?.displayChart(bars)
            }
        }
        
        viewModel.onDefaultInstrumentIndex = { [weak self] index in
            DispatchQueue.main.async {
                self?.picker.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        viewModel.onSubscriptionStatusChanged = { [weak self] isSubscribed in
            DispatchQueue.main.async {
                self?.subscribeButton.setTitle(isSubscribed ? "Unsubscribe" : "Subscribe", for: .normal)
            }
        }
    }
    
    private func onMainThread(_ execute: @escaping () -> Void) {
        DispatchQueue.main.async(execute: execute)
    }
    
    private func setupViews() {
        displaySymbol(emptyValue)
        displayPrice(emptyValue)
        displayTime(emptyValue)
        
        marketDataStack.layer.borderWidth = 2
        marketDataStack.layer.borderColor = UIColor.black.cgColor
        marketDataStack.layer.cornerRadius = 5
        
        chartView.layer.borderWidth = 2
        chartView.layer.borderColor = UIColor.black.cgColor
        chartView.layer.cornerRadius = 20
        
        input.layer.borderWidth = 2
        input.layer.borderColor = UIColor.black.cgColor
        
        subscribeButton.isEnabled = false
        
        picker.backgroundColor = .white
        picker.delegate = self
        picker.dataSource = self
        
        input.inputView = picker
        input.tintColor = .clear
        
        setupDonePickerButton()
    }
    
    private func displayChart(_ bars: [Bar]) {
        chartView.updateChart(bars)
    }
    
    private func displaySelectedInstrument() {
        if let selectedInstrument = viewModel.selectedInstrument {
            input.text = selectedInstrument.description
            subscribeButton.isEnabled = true
            displaySymbol(selectedInstrument.symbol)
            displayPrice(emptyValue)
            displayTime(emptyValue)
        }
    }
    
    private func setupDonePickerButton() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.dismissPicker))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        input.inputAccessoryView = toolBar
    }
    
    @objc func dismissPicker() {
        input.resignFirstResponder()
    }
    
    private func displaySymbol(_ symbol: String) {
        self.symbol.text = "Symbol\n\(symbol)"
    }
    
    private func displayPrice(_ price: String) {
        self.price.text = "Price\n\(price)"
    }
    
    private func displayTime(_ time: String) {
        self.time.text = "Time\n\(time)"
    }
}

extension PricesViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewModel.instruments.count
    }
}

extension PricesViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.unsubscribe()
        viewModel.selectedInstrument = viewModel.instruments[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        viewModel.instruments[row].description
    }
}

extension PricesViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        picker.reloadAllComponents()
    }
}

