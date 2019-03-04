//
//  ProfileView.swift
//
//  Created by Jon Knight on 08/05/2016.
//  Copyright © 2016 Identity Hipsters. All rights reserved.
//

import UIKit


@available(iOS 10.0, *)
class AccountsViewController: UIViewController {
    
    @IBOutlet weak var mScrollView: UIScrollView!
    var spinner:SpinnerView!

    
    func refreshView(refreshControl: UIRefreshControl?) {
        if (refreshControl != nil) { refreshControl!.endRefreshing() }
        self.view.setNeedsDisplay()

        spinner = startSpinner()
        SessionManager.currentSession.refreshAll(completionHandler: {
            self.stopSpinner(spinner:self.spinner)
            self.updateDisplay()
        }, failureHandler: {
            self.stopSpinner(spinner: self.spinner)
            SessionManager.currentSession.signout()
            self.performSegue(withIdentifier: "AccountsToLogin", sender: self)
        })
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad: AccountsView")
        super.viewDidLoad()

        if (SessionManager.currentSession.refreshRequired) {
            refreshView(refreshControl: nil)
        } else {
            self.updateDisplay()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: AccountsView")
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 

    struct Data {
        var value: Float
        var payee: String
        var date: Double
    }
    
    
    func friendlyDate(date: Double) -> String {
        let now = Date()
        let then = Date(timeIntervalSince1970: (date/1000))
        let secs = now.seconds(from: then)
        if (secs < 60) { return("just now") }
        if (secs < 3600) { return("\(secs/60) mins ago") }
        if (secs < 86400) { return("\(secs/3600) hours ago") }
        return("\(secs/86400) days ago")
    }
    

    func recentTransactions(target: String) -> [Data] {
        var data = [Data]()
        if let accounts = SessionManager.currentSession.accountDetails["Accounts"].array {
            for account in accounts {
                if (target == account["accountno"].stringValue) {
                    for item in account["transactions"].arrayValue {
                        data.append(Data(value: Float(item["value"].stringValue)!,
                                         payee: item["payee"].stringValue,
                                         date: Double(item["date"].stringValue)!))
                    }
                    data.sort(by: {$0.date > $1.date})
                    return Array(data.prefix(3))
                }
            }
        }
        return []
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

    
    func addRule(y:Int) {
        let hr = UIView()
        hr.frame = CGRect(x: 20, y: y, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
    }
    
    
    func confirm(title:String, message:String, yes:@escaping ()->Void, no:@escaping ()->Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in yes() }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in no() }))
        self.present(alert, animated: true)
    }
    
    
    func switchStateDidChange(_ sender:UISwitch!)
    {
        let state = (sender.isOn) ? "Freeze" : "UnFreeze"

        confirm(title: state + " Account", message: "Are you sure you would like to " + state + " this account?", yes: {
            
            self.spinner = self.startSpinner()
            SessionManager.currentSession.checkOAuthToken(login: false, successHandler: {
                let defaults = UserDefaults.standard
                let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
                let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
                
                var authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/" + uid + "/alexa/"
                authnUrl += sender.accessibilityIdentifier! + "/" + state.lowercased()
                
                let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                tokenRequest.httpMethod = "POST"
                tokenRequest.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                
                let httpRequest = URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                    data, response, error in
                    
                    // A client-side error occured
                    if error != nil {
                        print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
                    }
                    
                    let responseCode = (response as! HTTPURLResponse).statusCode
                    let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                    
                    self.stopSpinner(spinner:self.spinner)
                    if (responseCode == 200) {
                        self.refreshView(refreshControl: nil)
                    }
                    
                })
                httpRequest.resume()
            }, failureHandler: {
                self.stopSpinner(spinner:self.spinner)
                print("OAUTH TOKEN EXPIRED?")
            })
        }, no: {
            sender.setOn(!sender.isOn, animated: true)
        })
    }
    
    
    func updateDisplay() {
        // Delete previous content
        mScrollView.subviews.map { $0.removeFromSuperview() }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshView(refreshControl:)), for: .valueChanged)
        mScrollView.refreshControl = refreshControl
        mScrollView.isScrollEnabled = true
        mScrollView.isUserInteractionEnabled = true

        var py = 50
        
        if (SessionManager.currentSession.userProfileJson["frdpverified"][0] == "true") {
            // Title
            addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"TOTAL BALANCE")
            py = py + 100
            
            // Bank accounts
            let accounts = SessionManager.currentSession.accountDetails["Accounts"].array
            if ((accounts?.count)! > 0) {
                var balance : Float = 0.0
                for (index,account) in accounts!.enumerated() {

                    balance += account["balance"].floatValue
                    addRule(y: py)
                    py = py + 10
                    
                    var color = (account["active"].boolValue == true) ? UIColor.white : UIColor.darkGray
                    var desc = addLabel(x:20, y:py, textColor:color, size:20, text:account["description"].stringValue)
                    var label = addLabel(x:20, y:py, textColor:color, size:20, text:account["balance"].stringValue.currency())

                    color = (account["active"].boolValue == true) ? UIColor.lightGray : UIColor.darkGray

                    label.frame.origin.x = self.view.frame.width-20 - label.frame.size.width
                    var frame:CGRect = desc.frame
                    frame.size.width = self.view.frame.width-label.frame.size.width-30
                    desc.frame = frame
                    py = py + 25

                    let trans = recentTransactions(target: account["accountno"].stringValue)
                    for tran in trans {
                        
                        addLabel(x:30, y:py, textColor:color, size:16, text:tran.payee)
                        label = addLabel(x:30, y:py, textColor:color, size:16, text:String(tran.value).currency())
                        label.frame.origin.x = self.view.frame.width-20 - label.frame.size.width
                        py = py + 20
                        
                        label = addLabel(x:30, y:py, textColor:color, size:10, text:((tran.value < 0) ? "DEBIT" : "CREDIT"))

                        label = addLabel(x:30, y:py, textColor:color, size:10, text:friendlyDate(date: tran.date))
                        label.frame.origin.x = self.view.frame.width-20 - label.frame.size.width
                        py = py + 20
                    }
                    if (account["name"] == "creditcard") {
                        let toggle = UISwitch()
                        toggle.tag = index
                        toggle.frame.origin.y = CGFloat(py)
                        toggle.frame.origin.x = 30
                        toggle.onTintColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
                        toggle.isOn = (account["active"].boolValue == false)
                        toggle.accessibilityIdentifier = account["name"].stringValue
                        toggle.addTarget(self, action: #selector(AccountsViewController.switchStateDidChange(_:)), for: .valueChanged)
                        mScrollView.addSubview(toggle)
                        py += 30
                        let label = addLabel(x:100, y:py-25, textColor:UIColor.lightGray, size:16, text:"Temporarily Freeze")
                        if (account["active"].boolValue == false) {
                            label.text = "Account Frozen"
                        }
                        toggle.frame.origin.x = (self.view.frame.width - (toggle.frame.width + label.frame.width)) / 2
                        label.frame.origin.x = toggle.frame.origin.x + toggle.frame.width + 5
                    }
                    py = py + 10
                }

                // Total balance
                addLabel(x:20, y:75, textColor:UIColor.orange, size:56, text:String(balance).currency())
                
            } else {
                addRule(y: py)
                let hr = UIView()
                addLabel(x:20, y:75, textColor:UIColor.orange, size:64, text:String("0.00").currency())

                py = py + 60
            }
            
            if ((accounts?.count)! < 4) {
                addRule(y: py)
                py = py + 60
                
                var button = UIButton()
                button.frame = CGRect(x: 0, y: 0, width: 180, height: 60)
                button.center.x = self.view.center.x
                button.center.y = CGFloat(py)
                button.layer.cornerRadius = 30
                button.backgroundColor = #colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1)
                button.setTitleColor(UIColor.white, for: .normal)
                button.titleLabel!.font = UIFont(name:"Helvetica-Light", size: 20)
                button.setTitle("ADD ACCOUNT", for: .normal)
                button.addTarget(self, action: #selector(applyForAccount), for: .touchUpInside)
                mScrollView.addSubview(button)
                py = py + 40
            }
            mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))

        } else {
            
            addLabel(x:20, y:py, textColor:UIColor.lightGray, size:20, text:"WELCOME")
            addRule(y:py+25)
            
            var label = UILabel()
            label.frame = CGRect(x: 20, y: py+30, width: Int(view!.bounds.size.width-40), height: 200)
            label.textAlignment = .center
            label.textColor = UIColor.orange
            label.font = UIFont(name:"Helvetica-Light", size: 40)
            label.text = "Welcome to ForgeBank"
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            mScrollView.addSubview(label)
            
            let image = UIImage(named: "money")
            let imageView = UIImageView(image: image!.resizeImage(100, opaque: true))
            imageView.center.x = view!.center.x
            imageView.center.y = CGFloat(py+250)
            imageView.layer.cornerRadius = 50
            imageView.layer.masksToBounds = true
            imageView.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
            imageView.layer.borderWidth = 1
            mScrollView.addSubview(imageView)

            label = UILabel()
            label.frame = CGRect(x: 20, y: py+300, width: Int(view!.bounds.size.width-40), height: 200)
            label.textAlignment = .center
            label.textColor = UIColor.lightGray
            label.font = UIFont(name:"Helvetica-Light", size: 16)
            label.text = "Before you can apply for ForgeBank products we just need to verify your identity.\n\nIt's painless and only takes a minute.\n\nVisit the profile page to begin."
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            mScrollView.addSubview(label)
        }
    }
    

    func applyForAccount(_: UIButton) {
        self.performSegue(withIdentifier: "ToApplySegue", sender: self)
    }
    
}

