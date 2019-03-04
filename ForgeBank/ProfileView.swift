//
//  ProfileViewController.swift
//  ForgeBank
//
//  Created by Jon Knight on 27/12/2018.
//  Copyright © 2018 Identity Hipsters. All rights reserved.
//

import UIKit
import SafariServices


@available(iOS 10.0, *)
class ProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

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
            self.performSegue(withIdentifier: "ProfileToLogin", sender: self)
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateDisplay()
        //refreshView(refreshControl: nil)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ProfileView")
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
    
    
    func friendlyDate(date: Double) -> String {
        let now = Date()
        let then = Date(timeIntervalSince1970: (date/1000))
        let secs = now.seconds(from: then)
        if (secs < 60) { return("just now") }
        if (secs < 3600) { return("\(secs/60) mins ago") }
        if (secs < 86400) { return("\(secs/3600) hours ago") }
        return("\(secs/86400) days ago")
    }
    
    
    func addRule(y:Int) {
        let hr = UIView()
        hr.frame = CGRect(x: 20, y: y, width: Int(view!.bounds.size.width-40), height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
    }
    
    
    func switchStateDidChange(_ sender:UISwitch!)
    {
        if (sender.isOn) {
            UserDefaults.standard.set(true, forKey: "oneTouchLogin");
        } else         {
            UserDefaults.standard.removeObject(forKey: "oneTouchLogin")
        }
        UserDefaults.standard.synchronize()
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
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"ABOUT YOU")
        py = py + 25
        
        addRule(y:py)
        py = py + 10
        
        // Draw Profile Card
        var image = UIImage(named: "mountain")
        let hr = UIImageView(image: image)
        hr.frame = CGRect(x: 20, y: py, width: Int(view!.bounds.size.width-40), height: 200)
        hr.contentMode = UIViewContentMode.scaleAspectFill
        hr.clipsToBounds = true
        hr.layer.cornerRadius = 16
        mScrollView.addSubview(hr)
        
        
        addLabel(x:40, y:py+10, textColor:UIColor.orange, size:36, text:SessionManager.currentSession.userProfileJson["givenName"][0].stringValue)
        
        image = SessionManager.currentSession.userProfilePhoto.base64Convert()
        
        var button = UIButton()
        button.frame = CGRect(x: Int(view!.bounds.size.width-100), y: py+10, width: 60, height: 60)
        button.layer.cornerRadius = 30
        if (SessionManager.currentSession.userProfileJson["frdpverified"][0] == "true") {
            button.backgroundColor = UIColor(patternImage: (image?.resizeImage(100, opaque: true))!)
            button.layer.borderColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
            button.layer.borderWidth = 2
        } else {
            button.backgroundColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
            button.setTitleColor(UIColor.yellow, for: .normal)
            button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)
            button.setTitle("\u{f4fc}", for: .normal)
        }
        button.addTarget(self, action: #selector(verifyButtonAction), for: .touchUpInside)
        mScrollView.addSubview(button)

        
        addLabel(x:40, y:py+65, textColor:UIColor.white, size:20, text:SessionManager.currentSession.userProfileJson["cn"][0].stringValue)
        addLabel(x:40, y:py+95, textColor:UIColor.white, size:16, text:SessionManager.currentSession.userProfileJson["mail"][0].stringValue)
        if (SessionManager.currentSession.userProfileJson["postalAddress"].exists()) {
            addLabel(x:40, y:py+120, textColor:UIColor.white, size:16, text:SessionManager.currentSession.userProfileJson["postalAddress"][0].stringValue)
            hr.frame.size.height += 25
            py += 25
        }
        if (SessionManager.currentSession.userProfileJson["telephoneNumber"].exists()) {
            addLabel(x:40, y:py+120, textColor:UIColor.white, size:16, text:SessionManager.currentSession.userProfileJson["telephoneNumber"][0].stringValue)
            hr.frame.size.height += 25
            py += 25
        }
        if (SessionManager.currentSession.userProfileJson["frdpverified"][0] != "true") {
            addLabel(x:40, y:py+120, textColor:UIColor.yellow, size:20, text:"NOT VERIFIED")
            hr.frame.size.height += 25
            py += 25
        }
        py = py + 125
        
        if (SessionManager.currentSession.userProfileJson["frdpverified"][0] == "true") {
            button = UIButton()
            button.frame = CGRect(x: Int(view!.bounds.size.width-180), y: py, width: 60, height: 60)
            button.backgroundColor = .clear
            button.layer.cornerRadius = 30
            button.backgroundColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
            button.setTitleColor(UIColor.white, for: .normal)
            button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)
            button.setTitle("\u{f1b8}", for: .normal)
            button.addTarget(self, action: #selector(resetButtonAction), for: .touchUpInside)
            mScrollView.addSubview(button)
        }
        
        button = UIButton()
        button.frame = CGRect(x: Int(view!.bounds.size.width-100), y: py, width: 60, height: 60)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 30
        button.backgroundColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)
        button.setTitle("\u{f235}", for: .normal)
        button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        mScrollView.addSubview(button)

        py = py + 95
        
        var label = addLabel(x:20, y:py+5, textColor:UIColor.white, size:20, text:"One-Touch Login")

        let toggle = UISwitch()
        toggle.frame.origin.y = CGFloat(py)
        toggle.frame.origin.x = label.frame.size.width + 40
        toggle.onTintColor = #colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1)
        // If oauth token is stored then toggle s on
        toggle.isOn = (UserDefaults.standard.bool(forKey: "oneTouchLogin"))
        toggle.addTarget(self, action: #selector(switchStateDidChange(_:)), for: .valueChanged)
        mScrollView.addSubview(toggle)
        py = py + 60
        
        
        // Title
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"RECENT LOGINS")
        py = py + 25
        
        addRule(y:py)
        py = py + 10
                
        if (SessionManager.currentSession.userProfileJson["carLicense"].exists()) {
            var json = JSON.init(parseJSON: SessionManager.currentSession.userProfileJson["carLicense"][0].stringValue)
            if let logins = json.array {
                for login in logins {
                    let date = Date(timeIntervalSince1970: (Double(login["date"].stringValue)!/1000))

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm"

                    var label:UILabel
                    if (login["status"].stringValue == "SUCCESS") {
                        label = addLabel(x:40, y:py, textColor:#colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1), size:16, text:"\u{f164}")
                        label.frame.origin.x = self.view.frame.width-20 - label.frame.size.width

                    } else {
                        label = addLabel(x:40, y:py, textColor:#colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1), size:16, text:"\u{f165}")
                        label.frame.origin.x = self.view.frame.width-20 - label.frame.size.width
                    }
                    label.font = UIFont(name: "FontAwesome5FreeSolid", size:16)!
                    dateFormatter.dateFormat = "dd MMM yyyy"
                    addLabel(x:20, y:py, textColor:UIColor.lightGray, size:16, text:dateFormatter.string(from: date))
                    dateFormatter.dateFormat = "HH:mma"
                    label = addLabel(x:40, y:py, textColor:UIColor.lightGray, size:16, text:dateFormatter.string(from: date))
                    label.frame.origin.x = self.view.frame.width-50 - label.frame.size.width

                    addLabel(x:20, y:py+20, textColor:UIColor.lightGray, size:10, text:login["sharedState"]["authType"].stringValue.uppercased())
                    label = addLabel(x:30, y:py+20, textColor:UIColor.lightGray, size:10, text:" (" + friendlyDate(date: Double(login["date"].stringValue)!) + ")")
                    label.frame.origin.x = self.view.frame.width-50 - label.frame.size.width

                    py = py + 40
                }
            }
            mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))
        }
        
        py = py + 20
        // Diagnostics
        addLabel(x:20, y:py, textColor:UIColor.white, size:20, text:"UNDER THE COVERS")
        addRule(y:py + 25)

        addLabel(x:20, y:py+40, textColor:UIColor.white, size:16, text:"OAuth Response")
        label = UILabel()
        label.frame.origin.y = CGFloat(py+60)
        label.frame.origin.x = CGFloat(20)
        label.frame.size.width = view!.bounds.size.width-40
        label.textAlignment = .left
        label.textColor = UIColor.lightGray
        label.font = UIFont(name:"Helvetica-Light", size: CGFloat(12))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byCharWrapping
        label.text = SessionManager.currentSession.oauth.rawString() ?? ""
        label.sizeToFit()
        mScrollView.addSubview(label)
        py = py + Int(label.frame.height) + 55

        addLabel(x:20, y:py+35, textColor:UIColor.white, size:16, text:"OIDC Token")
        label = UILabel()
        label.frame.origin.y = CGFloat(py+55)
        label.frame.origin.x = CGFloat(20)
        label.frame.size.width = view!.bounds.size.width-40
        label.textAlignment = .left
        label.textColor = UIColor.lightGray
        label.font = UIFont(name:"Helvetica-Light", size: CGFloat(12))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byCharWrapping
        label.text = SessionManager.currentSession.idtoken.rawString() ?? ""
        label.sizeToFit()
        mScrollView.addSubview(label)
        py = py + Int(label.frame.height) + 60
        
        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))

    }
    
    
    func confirm(title:String, message:String, yes:@escaping ()->Void, no:@escaping ()->Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in yes() }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in no() }))
        self.present(alert, animated: true)
    }
    
    
    func resetButtonAction(sender: UIButton) {
        confirm(title: "Reset Transactions?", message: "Reset all your account transactions?", yes: {

            self.spinner = self.startSpinner()
            SessionManager.currentSession.checkOAuthToken(login: false, successHandler: {
                let defaults = UserDefaults.standard
                let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
                let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
                
                let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/" + uid + "/random"
                
                let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                tokenRequest.httpMethod = "PUT"
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
                        SessionManager.currentSession.refreshRequired = true
                        self.performSegue(withIdentifier: "AccountsView", sender: self)
                    } // JONK ELSE ERROR?
                })
                httpRequest.resume()
            }, failureHandler: {
                self.stopSpinner(spinner:self.spinner)
                print("OAUTH TOKEN EXPIRED?")
            })

        }, no: {
        })
    }
    
    
    func verifyButtonAction(sender: UIButton)
    {
        performSegue(withIdentifier: "VerifySegue", sender: nil)
    }
    
    
    func deleteButtonAction(sender: UIButton) {
        
        confirm(title: "Delete Account?", message: "This will remove this user's account. Are you sure?", yes: {
            self.spinner = self.startSpinner()
            SessionManager.currentSession.checkOAuthToken(login: false, successHandler: {
                let defaults = UserDefaults.standard
                let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
                let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
                
                let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/family/" + uid
                let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
                tokenRequest.httpMethod = "DELETE"
                tokenRequest.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                
                let httpRequest = URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                    data, response, error in
                    
                    // A client-side error occured
                    if error != nil {
                        print("Failed to send authentication request: \(error?.localizedDescription)!")
                    }
                    
                    let responseCode = (response as! HTTPURLResponse).statusCode
                    let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    //print("Authentication: received Response (\(responseCode)): \(responseData)")
                    
                    if (responseCode == 200) {
                        SessionManager.currentSession.signout()
                        self.performSegue(withIdentifier: "ProfileToLogin", sender: self)
                    } // JONK ELSE ERROR?
                })
                httpRequest.resume()
            }, failureHandler: {
                self.stopSpinner(spinner:self.spinner)
                print("OAUTH TOKEN EXPIRED?")
            })
        }, no: {
        })
    }
    
}
