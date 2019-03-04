//
//  ApplyView.swift
//  ForgeBank
//
//  Created by Jon Knight on 06/01/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//

import UIKit

class ApplyView: UIViewController {

    @IBOutlet weak var mScrollView: UIScrollView!
    
    var spinner:SpinnerView?
    var accounts = [ "current", "creditcard", "mortgage", "childaccount" ]
    var accountNames = [ "ForgeBank Current", "Infinite CreditCard", "ForgeBank Mortgage", "Early Saver" ]
    var accountDescs = [ "An everyday top-tier account, with the best rates and all the perks",
                         "Our most popular card, with unique benefits, premium travel and purchase protections",
                         "Forget fixed-rate, flexible-rate, trackers ... a mortgage that grows with your family",
                         "An easy and fun way to teach kids good money habits, with our unique parental controls" ]
    
    
    func drawLabel(text:String, y:Int, size: Int, colour:UIColor) {
        let label = UILabel()
        label.frame = CGRect(x: 20, y: y, width: Int(view!.bounds.size.width-40), height: 200)
        label.textAlignment = .center
        label.textColor = colour
        label.font = UIFont(name:"Helvetica-Light", size: CGFloat(size))
        label.text = text
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        mScrollView.addSubview(label)
    }
    
    
    func drawButton(y:Int, tag:Int) {
        let button = UIButton()
        button.tag = tag
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        button.center.x = self.view.center.x
        button.center.y = CGFloat(y+30)
        button.layer.cornerRadius = 30
        button.backgroundColor = #colorLiteral(red: 0.5074513555, green: 0.5972354412, blue: 0.8209660053, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"Helvetica-Light", size: 20)
        button.setTitle("APPLY", for: .normal)
        button.addTarget(self, action: #selector(applyButtonAction), for: .touchUpInside)
        mScrollView.addSubview(button)
    }
    
    
    func drawLine(y:Int){
        let hr = UIView()
        hr.frame = CGRect(x: 20, y: y, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateDisplay()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateDisplay()
    }
    
    
    func updateDisplay() {
        // Delete previous content
        mScrollView.subviews.map { $0.removeFromSuperview() }

        let button = UIButton()
        button.frame = CGRect(x: view.bounds.size.width-40 , y: 40, width: 24, height: 24)
        button.layer.cornerRadius = 12
        button.backgroundColor = #colorLiteral(red: 0.5074513555, green: 0.5972354412, blue: 0.8209660053, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 24)
        button.setTitle("\u{f057}", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        mScrollView.addSubview(button)
        
        var py = 40
        for (index,account) in accounts.enumerated() {
            
            var found = false
            let accs = SessionManager.currentSession.accountDetails["Accounts"].array
            for acc in accs! {
                if (acc["name"].stringValue == account) {
                    found = true
                }
            }
            if (!found) {
                print(account)
                drawLabel(text:accountNames[index], y:py, size:40, colour: .white)
                drawLabel(text:accountDescs[index], y:py+80, size:20, colour:.lightGray)
                drawButton(y: py+220, tag: index)
                drawLine(y: py+290)
                py += 250
            }
        }
        
        py += 60
        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))
    }
    
    
    func cancelButtonAction(send:UIButton) {
        self.performSegue(withIdentifier: "FromApplySegue", sender: self)
    }
    
    
    func applyButtonAction(sender:UIButton) {
        spinner = startSpinner()
        
        let defaults = UserDefaults.standard
        let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
        let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
        
        let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/" + uid + "/apply"
        
        let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        tokenRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let jsonBody: [String: Any] = [ "account": accounts[sender.tag] ]
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody)
        tokenRequest.httpBody = jsonData
        
        let httpRequest = URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
            data, response, error in
            
            // A client-side error occured
            if error != nil {
                print("Failed to send authentication request: \(String(describing: error?.localizedDescription))")
            }
            
            let responseCode = (response as! HTTPURLResponse).statusCode
            let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
            
            self.stopSpinner(spinner: self.spinner!)
            if (responseCode == 201) {
                SessionManager.currentSession.refreshRequired = true
            } // JONK ELSE ERROR
            self.performSegue(withIdentifier: "FromApplySegue", sender: self)
        })
        httpRequest.resume()

    }
    
    
}
