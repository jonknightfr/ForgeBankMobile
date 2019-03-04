//
//  AnalysisView.swift
//  ForgeBank
//
//  Created by Jon Knight on 01/01/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class AnalysisView: UIViewController {

    @IBOutlet weak var mScrollView: UIScrollView!
    var spinner:SpinnerView!

    var debits:[String:Double] = [:]
    var credits:[String:Double] = [:]
    var today:[String:Double] = [:]
    var colours = [ "Entertainment": #colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1), "Food": #colorLiteral(red: 0.5065105557, green: 0.5980392098, blue: 0.8174176812, alpha: 1), "Utilities": #colorLiteral(red: 0.6174510717, green: 0.3782832623, blue: 0.5289188027, alpha: 1), "Mortgage": #colorLiteral(red: 0.3307383657, green: 0.6436187029, blue: 0.5783983469, alpha: 1), "Transport": #colorLiteral(red: 0.9979146123, green: 0.5030351877, blue: 0.005148739088, alpha: 1), "Cash & ATM": #colorLiteral(red: 0.2085080743, green: 0.401401639, blue: 0.355112195, alpha: 1), "Transfer": #colorLiteral(red: 0.2951386571, green: 0.3820186853, blue: 0.5879971385, alpha: 1), "Salary": #colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1), "Savings": #colorLiteral(red: 0.6174510717, green: 0.3782832623, blue: 0.5289188027, alpha: 1), "Investments": #colorLiteral(red: 0.9979146123, green: 0.5030351877, blue: 0.005148739088, alpha: 1)]
    
    
    func friendlyDate(date: Double) -> String {
        let now = Date()
        let then = Date(timeIntervalSince1970: (date/1000))
        let secs = now.seconds(from: then)
        if (secs < 60) { return("just now") }
        if (secs < 3600) { return("\(secs/60) mins ago") }
        if (secs < 86400) { return("\(secs/3600) hours ago") }
        return("\(secs/86400) days ago")
    }
    
    
    func analyse() {
        let midnight = Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: Date())!.timeIntervalSince1970
        
        debits = [ "Entertainment": 0.0, "Food": 0.0, "Utilities": 0.0, "Mortgage": 0.0, "Transport": 0.0, "Cash & ATM": 0.0, "Transfer": 0.0 ]
        today = [ "Entertainment": 0.0, "Food": 0.0, "Utilities": 0.0, "Mortgage": 0.0, "Transport": 0.0, "Cash & ATM": 0.0, "Transfer": 0.0 ]
        credits = [ "Salary": 0.0, "Transfer": 0.0, "Investments": 0.0, "Mortgage": 0.0, "Savings": 0.0 ]
        if let accounts = SessionManager.currentSession.accountDetails["Accounts"].array {
            for account in accounts {
                for item in account["transactions"].arrayValue {
                    let value = Double(item["value"].stringValue)!
                    let type = item["category"].stringValue
                    if (value < 0) {
                        debits[type] = debits[type]! + abs(value)
                        if (item["date"].doubleValue/1000 >= midnight) {
                            today[type] = today[type]! + abs(value)
                        }
                    }
                    else { credits[type] = credits[type]! + abs(value) }
                }
            }
        }
    }
    
    
    func refreshView(refreshControl: UIRefreshControl?) {
        if (refreshControl != nil) { refreshControl!.endRefreshing() }
        self.view.setNeedsDisplay()
        spinner = startSpinner()
        SessionManager.currentSession.refreshAll(completionHandler: {
            self.stopSpinner(spinner: self.spinner)
            self.updateDisplay()
        }, failureHandler: {
            self.stopSpinner(spinner: self.spinner)
            SessionManager.currentSession.signout()
            self.performSegue(withIdentifier: "AnalysisToLogin", sender: self)
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateDisplay()
        //refreshView(refreshControl: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: AnalysisView")
        if (SessionManager.currentSession.refreshRequired) {
            refreshView(refreshControl: nil)
        } else {
            self.updateDisplay()
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateDisplay()
        }
    }
    
    
    func addLabel(x:Int, y:Int, textColor: UIColor, size:Int, text:String) -> UILabel{
        let label = UILabel()
        label.frame.origin.y = CGFloat(y)
        label.frame.origin.x = CGFloat(x)
        label.textAlignment = .left
        label.textColor = textColor
        label.font = UIFont(name:"Helvetica-Light", size: CGFloat(size))
        label.text = text
        label.sizeToFit()
        mScrollView.addSubview(label)
        return label
    }
    
    
    func updateDisplay() {
        // Delete previous content
        mScrollView.subviews.map { $0.removeFromSuperview() }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshView(refreshControl:)), for: .valueChanged)
        mScrollView.refreshControl = refreshControl
        mScrollView.isScrollEnabled = true
        mScrollView.isUserInteractionEnabled = true
        var py = 40
        
        analyse()
        
        // Title
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"YOUR SPENDING")
        py = py + 25

        var hr = UIView()
        hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
        py = py + 25
        
        let donut = Ring()
        donut.today = today
        donut.colours = colours
        donut.frame = CGRect(x:20, y:py, width: Int(view.bounds.width/2), height: Int(view.bounds.width/2))
        donut.center.x = view.bounds.width/2
        mScrollView.addSubview(donut)
        
        var total:Double = 0
        for (_,value) in today {
            total = total + value
        }
        var label = addLabel(x: 0, y: 0, textColor: UIColor.white, size: 20, text: String(total).currency())
        label.center = donut.center
        label.center.y -= 10
        label = addLabel(x: 0, y: 0, textColor: UIColor.lightGray, size: 16, text: "THIS WEEK")
        label.center = donut.center
        label.center.y += 10
        
        py = py + Int(view.bounds.width/2) + 20
        
        var highest = 0.0
        for (_,value) in debits {
            if (value > highest) { highest = value }
        }
        highest = highest * 1.2
        
        for (type,value) in debits {
            addLabel(x:20, y:py, textColor:UIColor.lightGray, size:16, text:type.uppercased())
            
            var hr = UIView()
            hr.frame = CGRect(x: 20, y: py+20, width: Int(view!.bounds.size.width-40), height: 26)
            hr.layer.cornerRadius = 10
            hr.backgroundColor = UIColor.darkGray
            mScrollView.addSubview(hr)

            var width = 0
            if (highest > 0) {
                width = Int(Float(view.bounds.width) * Float(value/highest))
            }
            hr = UIView()
            hr.frame = CGRect(x: 20, y: py+20, width: width, height: 26)
            hr.layer.cornerRadius = 15
            hr.backgroundColor = colours[type]
            mScrollView.addSubview(hr)
            
            let label = addLabel(x:20, y:py+25, textColor:UIColor.white, size:14, text:String(value).currency())
            label.center.x = view.bounds.width/2

            py = py + 55
        }
        py = py + 10
   
        // Title
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"YOUR INCOME")
        py = py + 25
        
        hr = UIView()
        hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
        py = py + 20
        
        highest = 0.0
        for (_,value) in credits {
            if (value > highest) { highest = value }
        }
        highest = highest * 1.2
        
        for (type,value) in credits {
            addLabel(x:20, y:py, textColor:UIColor.lightGray, size:16, text:type.uppercased())
            
            var hr = UIView()
            hr.frame = CGRect(x: 20, y: py+20, width: Int(view!.bounds.size.width-40), height: 26)
            hr.layer.cornerRadius = 10
            hr.backgroundColor = UIColor.darkGray
            mScrollView.addSubview(hr)
            
            var width = 0
            if (highest > 0) {
                width = Int(Float(view.bounds.width) * Float(value/highest))
            }
            hr = UIView()
            hr.frame = CGRect(x: 20, y: py+20, width: width, height: 26)
            hr.layer.cornerRadius = 15
            hr.backgroundColor = colours[type]
            mScrollView.addSubview(hr)
            
            let label = addLabel(x:20, y:py+25, textColor:UIColor.white, size:14, text:String(value).currency())
            label.center.x = view.bounds.width/2
            
            py = py + 55
        }
        
        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))
    }
}


class Ring:UIView
{
    var today:[String:Double] = [:]
    var colours:[String:UIColor] = [:]
    
    override func draw(_ rect: CGRect)
    {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        drawRingFittingInsideView(start:CGFloat(0), end:CGFloat(360), color:UIColor.darkGray.cgColor)
        var total:Double = 0
        for (_,value) in today {
            total = total + value
        }
        var arc:Double = 0
        for (type,value) in today {
            if (value > 0) {
                drawRingFittingInsideView(start:CGFloat(arc), end:CGFloat(arc+(360*value/total)), color:(colours[type]?.cgColor)!)
                arc = arc + 360*value/total
            }
        }
    }
    
    internal func drawRingFittingInsideView(start:CGFloat, end:CGFloat, color:CGColor)->()
    {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        let desiredLineWidth:CGFloat = 30    // your desired value
        
        let startAngleCalced: CGFloat = -start + 90
        let endAngleCalced: CGFloat = -end + 90
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:halfSize,y:halfSize),
            radius: CGFloat( halfSize - (desiredLineWidth/2) ),
            startAngle:-startAngleCalced * CGFloat(Double.pi)/180,
            endAngle:-endAngleCalced * CGFloat(Double.pi)/180,
            clockwise: true)
        circlePath.lineJoinStyle = .round
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = desiredLineWidth

        layer.addSublayer(shapeLayer)
        
        let shadowSubLayer = createShadowLayer()
        shadowSubLayer.insertSublayer(shapeLayer, at: 0)
        layer.addSublayer(shadowSubLayer)

    }
    
    func createShadowLayer() -> CALayer {
        let shadowLayer = CALayer()
        shadowLayer.shadowColor = UIColor.lightGray.cgColor
        shadowLayer.shadowOffset = CGSize.zero
        shadowLayer.shadowRadius = 10
        shadowLayer.shadowOpacity = 0.3
        shadowLayer.backgroundColor = UIColor.clear.cgColor
        return shadowLayer
    }
    
}
