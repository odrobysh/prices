import UIKit
import DGCharts
import Charts

class ChartView: UIView {
    private var candleChartView: CandleStickChartView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        candleChartView = CandleStickChartView()
        candleChartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(candleChartView)
        setConstraints()
        candleChartView.xAxis.labelPosition = .bottom
        candleChartView.xAxis.valueFormatter = DateValueFormatter()
        candleChartView.xAxis.labelCount = 5
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            candleChartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            candleChartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            candleChartView.topAnchor.constraint(equalTo: topAnchor),
            candleChartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func updateChart(_ bars: [Bar]) {
        
        var candleEntries: [CandleChartDataEntry] = []
        
        for bar in bars {
            let entry = CandleChartDataEntry(x: bar.t.timeIntervalSince1970,
                                             shadowH: bar.h,
                                             shadowL: bar.l,
                                             open: bar.o,
                                             close: bar.c)
            candleEntries.append(entry)
        }
        
        let candleDataSet = CandleChartDataSet(entries: candleEntries, label: "historical prices")
        candleDataSet.colors = [NSUIColor.blue]
        candleDataSet.decreasingColor = NSUIColor.red
        candleDataSet.increasingColor = NSUIColor.green
        candleDataSet.decreasingFilled = true
        candleDataSet.increasingFilled = true
        
        let candleData = CandleChartData(dataSet: candleDataSet)
        candleChartView.data = candleData
    }
}

class DateValueFormatter: AxisValueFormatter {
    let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm"
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return dateFormatter.string(from: date)
    }
}

