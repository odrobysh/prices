import UIKit
class ChartView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //common func to init our view
    private func setupView() {
        backgroundColor = .red
    }
    
    // temp
    func drawSimpleChart(_ bars: [Bar]) {
        // high
        guard let max = bars.map(\.h).max(),
              let min = bars.map(\.l).min()
        else { return }
        
        let ydelta = max - min
        
    }
    
    func displayChart() {//dots: [Dot]) {
        let pt1 = CGPoint(x: 20, y: 10)
        let pt2 = CGPoint(x: 70, y: 150)
        let pt3 = CGPoint(x: 120, y: 120)
        let pt4 = CGPoint(x: 170, y: 160)
        let pt5 = CGPoint(x: 220, y: 200)
        let pt6 = CGPoint(x: 270, y: 260)
        
        let path = UIBezierPath()
        path.move(to: pt1)
        path.addLine(to: pt2)
        path.addLine(to: pt3)
        path.addLine(to: pt4)
        path.addLine(to: pt5)
        path.addLine(to: pt6)

        path.stroke()
        //path.close()
        
        //Shape part
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.lineWidth = 10
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.green.cgColor
        layer.addSublayer(shape)
        
    }
}


