//
//  PayeesView.swift
//  ForgeBank
//
//  Created by Jon Knight on 23/12/2018.
//  Copyright © 2018 Identity Hipsters. All rights reserved.
//

import UIKit
import LocalAuthentication



@available(iOS 10.0, *)
class PayeesView: UIViewController {

    @IBOutlet weak var mScrollView: UIScrollView!
    var spinner:SpinnerView!
    
    
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
            self.performSegue(withIdentifier: "PayeesToLogin", sender: self)
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateDisplay()
        //refreshView(refreshControl: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: PayeesView")
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
    

    func addRule(y:Int) {
        let hr = UIView()
        hr.frame = CGRect(x: 20, y: y, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
    }
    
    
    func payButtonAction(sender: UIButton) {
        var payee = SessionManager.currentSession.accountDetails["payees"][sender.tag]
        
        let alert = UIAlertController(title: "Make payment to " + payee["name"].stringValue, message: "Payment amount", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = "0.00"
            textField.textAlignment = .center
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in print("cancelled") }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.approvePayment(payee: payee["name"].stringValue, value: alert.textFields![0].text!)
        }))
        
        self.present(alert, animated: true) {
            alert.textFields![0].selectAll(nil)
        }
    }
    
    
    func confirm(title:String, message:String, yes:@escaping ()->Void, no:@escaping ()->Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in yes() }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in no() }))
        self.present(alert, animated: true)
    }
    
    
    func familyButtonAction(sender: UIButton) {
        let family = SessionManager.currentSession.accountDetails["Family"][sender.tag]
        
        confirm(title: "Delete " + family["displayName"].stringValue, message: "Are you sure?", yes: {
            
            self.startSpinner()
            SessionManager.currentSession.checkOAuthToken(login: false, successHandler: {
                let defaults = UserDefaults.standard
                let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
                
                let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/family/" + family["userName"].stringValue
                
                let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                tokenRequest.httpMethod = "DELETE"
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
                    
                    if (responseCode == 200) {
                        SessionManager.currentSession.refreshAccountDetails(completionHandler: {
                            SessionManager.currentSession.refreshUserAppDetails(completionHandler: {
                                self.stopSpinner(spinner: self.spinner)
                                self.updateDisplay()
                            }, failureHander: {
                                self.stopSpinner(spinner: self.spinner)
                            })
                        }, failureHandler: {
                            self.stopSpinner(spinner: self.spinner)
                        })
                    } // JONK ELSE ERROR?
                })
                httpRequest.resume()
            }, failureHandler: {
                self.stopSpinner(spinner: self.spinner)
                print("OAUTH TOKEN EXPIRED?")
            })
        }, no: {
        })
    }
    
    
    func appButtonAction(sender: UIButton) {
        let app = SessionManager.currentSession.oauthApps["result"][sender.tag]

        confirm(title: "Delete app " + app["name"].stringValue, message: "Are you sure?", yes: {
            
            self.startSpinner()
            SessionManager.currentSession.checkOAuthToken(login: false, successHandler: {
                let defaults = UserDefaults.standard
                let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
                
                let authnUrl = defaults.string(forKey: "bank_host")! + "/openam/json/users/" + uid + "/oauth2/applications/" + app["_id"].stringValue
                
                let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                tokenRequest.httpMethod = "DELETE"
                tokenRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                tokenRequest.addValue("iPlanetDirectoryPro=" + SessionManager.currentSession.tokenId, forHTTPHeaderField: "Cookie")
                tokenRequest.addValue("XmlHttpRequest", forHTTPHeaderField: "X-Requested-With")
                tokenRequest.addValue("*", forHTTPHeaderField: "If-Match")
                
                let httpRequest = URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                    data, response, error in
                    
                    // A client-side error occured
                    if error != nil {
                        print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
                    }
                    
                    let responseCode = (response as! HTTPURLResponse).statusCode
                    let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    //print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                    
                    // JONK this needs replacing
                    if (responseCode == 200) {
                        SessionManager.currentSession.refreshAccountDetails(completionHandler: {
                            SessionManager.currentSession.refreshUserAppDetails(completionHandler: {
                                self.stopSpinner(spinner: self.spinner)
                                self.updateDisplay()
                            }, failureHander: {
                                self.stopSpinner(spinner: self.spinner)
                            })
                        }, failureHandler: {
                            self.stopSpinner(spinner: self.spinner)
                        })
                    } // JONK ELSE ERROR?
                })
                httpRequest.resume()
            }, failureHandler: {
                self.stopSpinner(spinner: self.spinner)
                print("OAUTH TOKEN EXPIRED")
            })
        }, no: {
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
        
        // Title
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"PAYEES")
        py = py + 25
            
        var payees = SessionManager.currentSession.accountDetails["payees"].array
        if ((payees != nil) && (payees!.count > 0)) {
            for (index, payee) in payees!.enumerated() {

                addRule(y:py)
                py = py + 10
                
                // Draw Payee Card
                var image = UIImage(named: "mountain")
                var hr = UIImageView(image: image)
                hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 130)
                hr.contentMode = UIViewContentMode.scaleAspectFill
                hr.clipsToBounds = true
                hr.layer.cornerRadius = 16
                mScrollView.addSubview(hr)
                
                // Add Payee details
                addLabel(x:40, y:py+10, textColor:UIColor.white, size:28, text:payee["nickname"].stringValue)
                
                // Payee full name
                addLabel(x:40, y:py+60, textColor:UIColor.white, size:20, text:payee["name"].stringValue)
                
                // Payee bank account details
                var label = addLabel(x:40, y:py+85, textColor:UIColor.white, size:14, text:payee["acc_no"].stringValue + " / " + payee["sort_code"].stringValue)
                label.textAlignment = .center
                
                // Pay button
                let button = UIButton()
                button.tag = index
                button.frame = CGRect(x: Int(view!.bounds.size.width-100), y: py+10, width: 60, height: 60)
                button.backgroundColor = .clear
                button.layer.cornerRadius = 30
                button.backgroundColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
                button.setTitleColor(UIColor.white, for: .normal)
                button.setTitle("Pay", for: .normal)
                button.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)
                mScrollView.addSubview(button)
                
                py = py + 140
            }
        } else {
            addRule(y:py)
            addLabel(x:20, y:py+10, textColor:UIColor.lightGray, size:20, text:"You have no payees set up.")
            py = py + 50
        }
        py = py + 20
        
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"FAMILY")
        py = py + 25
        
        payees = SessionManager.currentSession.accountDetails["Family"].array
        if ((payees != nil) && (payees!.count > 0)) {
            for (index, payee) in payees!.enumerated() {

                addRule(y:py)
                py = py + 10
                
                // Draw Payee Card
                var image = UIImage(named: "mountain-red")
                var hr = UIImageView(image: image)
                hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 130)
                hr.contentMode = UIViewContentMode.scaleAspectFill
                hr.clipsToBounds = true
                hr.layer.cornerRadius = 16
                mScrollView.addSubview(hr)
                
                
                // Add Payee details
                addLabel(x:40, y:py+10, textColor:UIColor.white, size:28, text:payee["givenName"].stringValue)
                
                // Payee full name
                addLabel(x:40, y:py+60, textColor:UIColor.white, size:20, text:payee["displayName"].stringValue)
                
                // Payee bank account details
                let label = addLabel(x:40, y:py+85, textColor:UIColor.white, size:14, text:payee["mail"].stringValue)
                label.textAlignment = .center
                
                let button = UIButton()
                button.tag = index
                button.frame = CGRect(x: Int(view!.bounds.size.width-100), y: py+10, width: 60, height: 60)
                button.backgroundColor = .clear
                button.layer.cornerRadius = 30
                button.backgroundColor = #colorLiteral(red: 0.7014767528, green: 0.4293239117, blue: 0.5986014009, alpha: 1)
                button.setTitleColor(UIColor.white, for: .normal)
                button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)!
                button.setTitle("\u{f235}", for: .normal)
                button.addTarget(self, action: #selector(familyButtonAction), for: .touchUpInside)
                mScrollView.addSubview(button)
                py = py + 140
            }
        } else {
            addRule(y:py)
            var label = addLabel(x:20, y:py+10, textColor:UIColor.lightGray, size:20, text:"You have no shared accounts.")
            py = py + 50
        }
        py = py + 20

        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"APPROVED APPS")
        py = py + 25
        
        if let apps = SessionManager.currentSession.oauthApps["result"].array {
            for (index, app) in apps.enumerated() {
                                
                addRule(y:py)
                py = py + 10
                
                // Draw App Card
                var image = UIImage(named: "mountain-blue")
                var hr = UIImageView(image: image)
                hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 100)
                hr.contentMode = UIViewContentMode.scaleAspectFill
                hr.clipsToBounds = true
                hr.layer.cornerRadius = 16
                mScrollView.addSubview(hr)
                
                // Add App name
                addLabel(x:40, y:py+10, textColor:UIColor.white, size:28, text:app["name"].stringValue)
                
                // App expiry
                var dateStr = "Approved until removed"
                if (app["expiryDateTime"].stringValue != "") {
                    let dateFormatterISO = ISO8601DateFormatter()
                    dateFormatterISO.formatOptions = [.withFullDate,.withTime,.withDashSeparatorInDate,.withColonSeparatorInTime]
                    let date = dateFormatterISO.date(from:app["expiryDateTime"].stringValue)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd MMM yyyy"
                    dateStr = "Approved until " + dateFormatter.string(from: date!)
                }
                addLabel(x:40, y:py+60, textColor:UIColor.white, size:14, text:dateStr)
                
                // Delete button
                let button = UIButton()
                button.tag = index
                button.frame = CGRect(x: Int(view!.bounds.size.width-100), y: py+10, width: 60, height: 60)
                button.backgroundColor = .clear
                button.layer.cornerRadius = 30
                button.backgroundColor = #colorLiteral(red: 0.5074513555, green: 0.5972354412, blue: 0.8209660053, alpha: 1)
                button.setTitleColor(UIColor.white, for: .normal)
                button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)!
                button.setTitle("\u{f1f8}", for: .normal)
                button.addTarget(self, action: #selector(appButtonAction), for: .touchUpInside)
                mScrollView.addSubview(button)
                
                // App scopes
                for (_, subJson) in app["scopes"] {
                    addLabel(x:50, y:py+85, textColor:UIColor.white, size:10, text:"\u{2022} " + subJson.stringValue)
                    py = py + 15
                    hr.frame.size.height += 15
                }
                
                py = py + 110
            }
        }
        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))
    }

    
    func approvePayment(payee:String, value: String) {
        let authorization = LAContext()
        let authPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        
        var authorizationError: NSError?
        if(authorization.canEvaluatePolicy(authPolicy, error: &authorizationError)){
            // if device is touch id capable do something here
            authorization.evaluatePolicy(authPolicy, localizedReason: "Touch the fingerprint sensor to approve payment of " + value.currency() + " to " + payee, reply: {(success,error) in
                if(success){
                    let defaults = UserDefaults.standard
                    let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
                    let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
                    
                    let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/" + uid + "/payee/transfer/" + value
                    
                    let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                    tokenRequest.httpMethod = "POST"
                    tokenRequest.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                    tokenRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    
                    let lat = String(SessionManager.currentSession.location.coordinate.latitude)
                    let lon = String(SessionManager.currentSession.location.coordinate.longitude)
                    
                    let str = "{ \"payee\":\""+payee+"\", \"mfa\": [\""+UIDevice.current.name+"\"], \"authorised\":[\""+uid+"\"], \"geolocation\":\"{\\\"lat\\\":"+lat+",\\\"lon\\\":"+lon+"}\" }"

                    tokenRequest.httpBody = str.data(using: .utf8)
                    
                    URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                        data, response, error in
                        
                        // A client-side error occured
                        if error != nil {
                            print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
                        }
                        
                        let responseCode = (response as! HTTPURLResponse).statusCode
                        let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                        //print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                        
                        if (responseCode == 200) {
                            SessionManager.currentSession.refreshRequired = true
                            DispatchQueue.main.async(execute: {
                                self.touchIDSuccessAlert()
                            });
                        } // JONK ELSE ERROR?
                    }).resume()
                    
                } else {
                    print(error!.localizedDescription)
                    DispatchQueue.main.async(execute: {
                        self.touchIDFailureAlert()
                    });
                }
            })
        } else {
            // add alert
            // JONK TODO
            print("Not Touch ID Capable")
        }
    }

    
    func touchIDFailureAlert() {
        let noTouchAlert : UIAlertView = UIAlertView(title: "Touch ID failed", message: "Sorry", delegate: self, cancelButtonTitle: "Okay")
        noTouchAlert.show()
    }
    
    func touchIDSuccessAlert() {
        let noTouchAlert : UIAlertView = UIAlertView(title: "Touch ID success", message: "Payment Approved", delegate: self, cancelButtonTitle: "Okay")
        noTouchAlert.show()
    }
    
}

