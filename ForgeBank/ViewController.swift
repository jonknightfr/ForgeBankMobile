//
//  ViewController.swift
//


import UIKit
import SafariServices
import CoreTelephony
import LocalAuthentication
import CoreLocation


class ViewController: UIViewController, UITextFieldDelegate, SFSafariViewControllerDelegate, CLLocationManagerDelegate  {

    // Previously used to gather a device print
    /*
    func getDeviceType() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var machineString : String = ""
        machineString = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return machineString
    }
 
    func getDeviceFreeSpace() -> Int64 {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectoryPath.last!) {
            if let freeSize = systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        }
        // something failed
        return 0
    }
    
     */
    func getCarrierInfo() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        if let carrierName = carrier?.carrierName {
            return carrierName
        } else {
            return ""
        }
    }
    
    /*
    func getInstalledApps() -> String {
        var apps: String = "["
        for each in ["sms://","tel://","maps://"] {
            if UIApplication.shared.canOpenURL(URL(string: "\(each)")!) {
                if apps != "[" { apps += "," }
                apps += "\"\(each)\""
            }
        }
        apps += "]"
        return apps
    }
 
    func getUDID() {
        SessionManager.currentSession.deviceJson = JSON(["deviceType":getDeviceType()])
        
        SessionManager.currentSession.deviceJson["uuid"] = JSON(UserDefaults.standard.value(forKey: "UDID")!)
        SessionManager.currentSession.deviceJson["freeSpace"].int64 = getDeviceFreeSpace()
        SessionManager.currentSession.deviceJson["model"] = JSON(UIDevice.current.model)
        SessionManager.currentSession.deviceJson["name"] = JSON(UIDevice.current.name)
        SessionManager.currentSession.deviceJson["systemName"] = JSON(UIDevice.current.systemName)
        SessionManager.currentSession.deviceJson["systemVersion"] = JSON(UIDevice.current.systemVersion)
        SessionManager.currentSession.deviceJson["timeZone"] = JSON(TimeZone.current.identifier)
        SessionManager.currentSession.deviceJson["locale"] = JSON(Locale.autoupdatingCurrent.identifier)
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") {
            SessionManager.currentSession.deviceJson["jailbreak"] = "true"
        } else {
            SessionManager.currentSession.deviceJson["jailbreak"] = "false"
        }
        SessionManager.currentSession.deviceJson["carrierInfo"] = JSON(getCarrierInfo())
        
        SessionManager.currentSession.deviceJson["installedApps"] = JSON(getInstalledApps())
        
        print("Device JSON = \(SessionManager.currentSession.deviceJson)")
    }
    */
 
    var touchIDfails = 0
    var registrationCode = ""
    var registerBody: [String: Any] = [:]
    var button: UIButton!
    let locationManager = CLLocationManager()
    var messageTexts: [String] = [ "ForgeBank Mobile", "A simpler way to bank", "A safer way to spend", "A smarter way to save", "Powered by ForgeRock" ]
    var animating = false
    
    
    func browserLogin() {
        let defaults = UserDefaults.standard
        let oauthURL = NSURL(string: defaults.string(forKey: "bank_host")! + "/openam/oauth2/authorize?response_type=code&scope=uid%20openid&decision=allow&client_id=mobileapp&redirect_uri=forgebank://oidc_callback")! as URL
        let safariVC = SFSafariViewController(url: oauthURL)
        self.present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }
    

    func actionLogin() {
        animating = false
        SessionManager.currentSession.checkOAuthToken(login: true, successHandler: {
            let authorization = LAContext()
            let authPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
            
            var authorizationError: NSError?
            if (authorization.canEvaluatePolicy(authPolicy, error: &authorizationError)) {
                // if device is touch id capable do something here
                authorization.evaluatePolicy(authPolicy, localizedReason: "Touch the fingerprint sensor to login", reply: {(success,error) in
                    if(success){
                        let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "BankPageViewController") as UIViewController
                        DispatchQueue.main.async(execute: {
                            let app = UIApplication.shared.delegate as! AppDelegate
                            app.window = UIWindow(frame: UIScreen.main.bounds)
                            app.window?.rootViewController = initialViewControlleripad
                            app.window?.makeKeyAndVisible()
                        });
                    } else {
                        print(error!.localizedDescription)
                        DispatchQueue.main.async(execute: {
                            self.touchIDFailureAlert()
                        });
                    }
                })
            } else {
                // add alert
                print("Not Touch ID Capable")
                if UserDefaults.standard.string(forKey: "web_login") == "Web Login" { self.browserLogin() }
                else { self.RESTLogin() }
            }
        }, failureHandler: {
            if UserDefaults.standard.string(forKey: "web_login") == "Web Login" { self.browserLogin() }
            else { self.RESTLogin() }
        })
    }
 
    
    func RESTsignUp() {
        authState = JSON("")
        RESTLogin(tree: "OnboardTree")
    }
    
    
    var authState:JSON = JSON("")
    var inputs:[UIView] = []
    
    func RESTLogin(tree:String = "Mobile") {
        let defaults = UserDefaults.standard
        
        let authnUrl = defaults.string(forKey: "bank_host")! + "/openam/json/authenticate?authIndexType=service&authIndexValue=" + tree
        print ("OpenAM URL \(authnUrl)")
        
        let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.httpBody = authState.rawString(options:[])!.data(using: String.Encoding.utf8)
        tokenRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        tokenRequest.addValue("Please confirm your login to ForgeBank", forHTTPHeaderField: "X-PushMessage")
        tokenRequest.addValue("protocol=1.0,resource=2.0", forHTTPHeaderField: "Accept-API-Version")
        tokenRequest.addValue("iPhone REST", forHTTPHeaderField: "User-Agent")

        print("SENDING: \(authState.rawString(options:[]))")
        
        URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
            data, response, error in
            
            // A client-side error occured
            if error != nil {
                print("Failed to send authentication request: \(error?.localizedDescription)!")
            }
            
            let responseCode = (response as! HTTPURLResponse).statusCode
            let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("Authentication: received Response (\(responseCode)): \(responseData)")
            
            if (responseCode == 200) {
                let dataFromString = responseData!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
                self.authState = JSON(data: dataFromString!)
                if (self.authState["tokenId"].exists()) {
                    SessionManager.currentSession.tokenId = self.authState["tokenId"].stringValue
                    print("AUTHENTICATED!")
                    SessionManager.currentSession.getOAuthGrantCode()
                } else {
                    DispatchQueue.main.async {
                        self.renderCallbacks()
                    }
                }
            } else if (responseCode == 401) {
                let dataFromString = responseData!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
                let reason = JSON(data: dataFromString!)
                if (reason["detail"].exists()) && (reason["detail"]["failureUrl"] == "LOCKED") {
                    print("LOCKED")
                    let alertController = UIAlertController(title: "Locked", message:
                        "Sorry, this device has been reported as retired and we have notified the owner.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                    self.authState = JSON("")
                    self.viewDidLoad()
                }
            } else {
                self.authState = JSON("")
                self.RESTLogin()
            }
        }).resume()
    }
 
    
    func addLabel(py:CGFloat, callback:JSON) -> UILabel {
        let label = UILabel()
        label.frame.origin.x = 0
        label.frame.origin.y = py+5
        label.frame.size.width = view!.bounds.size.width
        label.frame.size.height = 50
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.backgroundColor = #colorLiteral(red: 0.854362011, green: 0.4875436425, blue: 0.04479524493, alpha: 1)
        label.font = UIFont(name: "FontAwesome5FreeSolid", size:28)!
        switch callback["type"] {
            case "NameCallback":
                if (callback["output"][0]["value"].stringValue.lowercased().contains("email")) {
                    label.text = "  \u{f0e0}"
                } else {
                    label.text = "  \u{f2c2}"
                }
            case "PasswordCallback":
                label.text = "  \u{f084}"
            default:
                print("Unhandled callback")
            
        }
        return label
    }
    
    
    func addText(py:CGFloat, callback:JSON) -> UITextField {
        let textInput = UITextField()
        textInput.isSecureTextEntry = (callback["type"] == "PasswordCallback")
        textInput.frame.origin.y = py+10
        textInput.frame.size.width = view!.bounds.size.width - 200
        textInput.frame.size.height = 40
        textInput.textAlignment = .center
        textInput.textColor = UIColor.black
        textInput.backgroundColor = #colorLiteral(red: 0.854362011, green: 0.4875436425, blue: 0.04479524493, alpha: 1)
        textInput.font = UIFont(name:"Helvetica", size: 20)
        textInput.placeholder = callback["output"][0]["value"].stringValue
        let str = callback["output"][0]["value"].stringValue
        textInput.attributedPlaceholder = NSAttributedString(string:callback["output"][0]["value"].stringValue, attributes: [NSForegroundColorAttributeName: UIColor.white])
        textInput.center.x = view!.bounds.width / 2

        return textInput
    }
    
    
    func renderCallbacks() {
        self.button.isHidden = true
        view.subviews.forEach({
            if !($0 is UIImageView) {
                $0.removeFromSuperview()
            }
        })
        var py:CGFloat = view!.bounds.size.height - 206
        inputs.removeAll()
        if let callbacks = authState["callbacks"].array {
            for (index, callback) in callbacks.reversed().enumerated() {

                if callback["type"] == "PasswordCallback" {
                    let label = addLabel(py:py, callback:callback)
                    view.addSubview(label)
                    let textInput = addText(py:py, callback:callback)
                    view.addSubview(textInput)
                    inputs.insert(textInput, at:0)
                    py -= 53
                } else if callback["type"] == "NameCallback" {
                    let label = addLabel(py:py, callback:callback)
                    view.addSubview(label)
                    let textInput = addText(py:py, callback:callback)
                    view.addSubview(textInput)
                    inputs.insert(textInput,at:0)
                    py -= 53
                }
            }
        }
        
        // Next button - if no user interaction then just continue
        if (inputs.count == 0) { continueAuth() }
        else {
            let button = UIButton()
            button.frame.origin.x = 0
            button.frame.origin.y = view!.bounds.size.height - 140
            button.frame.size.width = view!.bounds.size.width
            button.frame.size.height = 50
            button.backgroundColor = #colorLiteral(red: 0.920394361, green: 0.6160387993, blue: 0.01928387396, alpha: 1)
            button.setTitleColor(UIColor.white, for: .normal)
            button.titleLabel!.font = UIFont(name:"Helvetica-Light", size: 16)!
            button.setTitle("Next", for: .normal)
            button.addTarget(self, action: #selector(continueAuth), for: .touchUpInside)
            view.addSubview(button)
            inputs.append(button)
        }
        
        // Join ForgeRock button
        var button = UIButton()
        button.frame.origin.x = 0
        button.frame.origin.y = view!.bounds.size.height - 80
        button.frame.size.width = view!.bounds.size.width
        button.frame.size.height = 50
        button.backgroundColor = #colorLiteral(red: 0.920394361, green: 0.6160387993, blue: 0.01928387396, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"Helvetica-Light", size: 16)!
        button.setTitle("Join ForgeBank", for: .normal)
        button.addTarget(self, action: #selector(RESTsignUp), for: .touchUpInside)
        view.addSubview(button)
        inputs.append(button)
        
        // Back button
        button = UIButton()
        button.frame.origin.x = 10
        button.frame.origin.y = 50
        button.frame.size.width = 20
        button.frame.size.height = 20
        button.backgroundColor = .clear
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 20)
        button.setTitle("\u{f137}", for: .normal)
        button.addTarget(self, action: #selector(viewDidLoad), for: .touchUpInside)
        view.addSubview(button)
        inputs.append(button)
    }
    
    
    func continueAuth() {
        var touchId = false
        
        if let callbacks = authState["callbacks"].array {
            for (index, callback) in callbacks.enumerated() {
                switch callback["type"] {
                case "NameCallback", "PasswordCallback":
                    let str = (inputs[index] as! UITextField).text!
                    authState["callbacks"][index]["input"][0]["value"] = JSON(str)
                case "TextOutputCallback":
                    if (callback["output"][1]["value"].stringValue == "4") {
                        var jsonIn = JSON(parseJSON: callback["output"][0]["value"].stringValue)
                        var jsonOut = JSON([:])
                        if jsonIn["deviceGeo"].boolValue && (SessionManager.currentSession.location != nil)  {
                            jsonOut["deviceGeo"] = JSON("{ \"latitude\": \"\(SessionManager.currentSession.location.coordinate.latitude)\",\"longitude\": \"\(SessionManager.currentSession.location.coordinate.longitude)\" }")
                        }
                        if (jsonIn["deviceName"].boolValue) {
                            jsonOut["deviceName"] = JSON(UIDevice.current.name)
                        }
                        if (jsonIn["deviceUUID"].boolValue) {
                            jsonOut["deviceUUID"] = JSON(UIDevice.current.identifierForVendor!.uuidString)
                        }
                        if (jsonIn["deviceCarrier"].boolValue) {
                            jsonOut["deviceCarrier"] = JSON(getCarrierInfo())
                        }
                        if (jsonIn["deviceAuth"].boolValue) {
                            let authorization = LAContext()
                            let authPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
                            touchId = true
                            authorization.evaluatePolicy(authPolicy, localizedReason: "Touch the fingerprint sensor to login", reply: {(success,error) in
                                if (success) {
                                    jsonOut["deviceAuth"] = JSON(true)
                                    self.authState["callbacks"][1]["input"][0]["value"] = JSON(jsonOut.rawString(options:[]))
                                    self.RESTLogin()
                                } else {
                                    jsonOut["deviceAuth"] = JSON(false)
                                    self.authState["callbacks"][1]["input"][0]["value"] = JSON(jsonOut.rawString(options:[]))
                                    self.RESTLogin()
                                }
                            })
                        }
                        
                        if !touchId {
                            authState["callbacks"][1]["input"][0]["value"] = JSON(jsonOut.rawString(options:[]))
                        }
                    }
                default:
                    print("Unhandled callback")
                }
            }
        }
        if !touchId { RESTLogin() }
    }
    
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func touchIDFailureAlert() {
        touchIDfails += 1
        // Too many failures, revert to normal sign in
        if (touchIDfails >= 3) { SessionManager.currentSession.signout() }
        let noTouchAlert : UIAlertView = UIAlertView(title: "Touch ID failed", message: "Sorry", delegate: self, cancelButtonTitle: "Okay")
        noTouchAlert.show()
    }
    
    func touchIDSuccessAlert() {
        touchIDfails = 0
        let noTouchAlert : UIAlertView = UIAlertView(title: "Touch ID success", message: "Approved", delegate: self, cancelButtonTitle: "Okay")
        noTouchAlert.show()
    }
    
    
    func registerSettingsBundle(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    
    
    func keyboardWillShow(sender: NSNotification) {
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            print(keyboardHeight)
            self.view.frame.origin.y = 0 - keyboardHeight // Move view points upward
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y = 0 // Move view to original position
    }
    
    
    override func viewDidLoad() {
        print("ViewController: viewDidLoad")
        super.viewDidLoad()
        
        authState = JSON("")
        view.subviews.forEach({
            $0.removeFromSuperview()
        })
        inputs.removeAll()
        
        
        // Handle keyboard obsuring inputs
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Draw background gradient
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [ #colorLiteral(red: 0.7918985486, green: 0.4595604539, blue: 0.06233157963, alpha: 1).cgColor, #colorLiteral(red: 0.9875505567, green: 0.6812157035, blue: 0, alpha: 1).cgColor ]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.view.layer.insertSublayer(gradient, at: 0)
        
        // Start to get location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        // Render logo
        let logoImage = UIImage(named: "ForgeBank-logo")
        let logo = UIImageView(image: logoImage)
        logo.frame.size.width = (view!.bounds.size.width * 2 / 5)
        logo.frame.size.height = logo.frame.size.width * (logoImage!.size.height / logoImage!.size.width)
        logo.center = self.view.center
        logo.center.y = 100
        logo.contentMode = UIViewContentMode.scaleAspectFill
        self.view.addSubview(logo)

        // Render start button
        button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        button.center = self.view.center
        button.backgroundColor = #colorLiteral(red: 0.854362011, green: 0.4875436425, blue: 0.04479524493, alpha: 1)
        button.layer.cornerRadius = 60
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 64)
        button.setTitle("\u{f52e}", for: .normal)
        button.addTarget(self, action: #selector(actionLogin), for: .touchUpInside)
        self.view.addSubview(button)
        
        // Version number
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
        var label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont(name:"Helvetica-Light", size: 14)
        label.text = "v\(appVersion ?? "")"
        label.sizeToFit()
        label.center.x = self.view.center.x
        label.center.y = logo.center.y + (logo.frame.size.height/2) + 5
        self.view.addSubview(label)
        
        // Check if app is registered to ForgeRock staff
        // JONK TURN THIS BACK ON!!!
        checkAppRegister()
  
        label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont(name:"Helvetica-Light", size: 24)
        label.text = "Welcome to ForgeBank"
        label.frame = CGRect(x: 20, y: Int(view!.bounds.size.height-250), width: Int(view!.bounds.size.width-40), height: 200)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        label.center.x = self.view.center.x
        self.view.addSubview(label)
        
        animating = true
        animateLabel(label:label, msg:0)
        
    }

    
    func animateLabel(label:UILabel, msg:Int) -> Void {
        if animating {
            var mesg = msg
            if (mesg >= messageTexts.count) { mesg = 0 }
            label.text = messageTexts[mesg]
            label.center.x = self.view.frame.size.width * 3/2
            UIView.animate(withDuration: 0.5, delay: 0.2, options:[UIViewAnimationOptions.curveEaseOut], animations: {
                label.center.x = self.view.center.x
            }, completion: {_ in
                UIView.animate(withDuration: 0.5, delay: 3.0, options:[UIViewAnimationOptions.curveEaseIn], animations: {
                    label.center.x = 0 - (self.view.frame.size.width / 2)
                }, completion: {_ in self.animateLabel(label: label, msg: mesg+1) } )
            } )
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            SessionManager.currentSession.location = location
            print("Found user's location: \(location)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    
    func checkAppRegister() {
        let defaults = UserDefaults.standard
        let registered = defaults.double(forKey: "registered")
        if (registered == nil) {
            DispatchQueue.main.async(execute: {
                self.registerEmailAlert()
            });
        } else {
            let now = Date()
            let then = Date(timeIntervalSince1970: registered)
            let days = now.days(from: then)
            if (days > 90) {
                DispatchQueue.main.async(execute: {
                    self.registerEmailAlert()
                });
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func generateRandomDigits(_ digitNumber: Int) -> String {
        var number = ""
        for i in 0..<digitNumber {
            var randomNumber = arc4random_uniform(10)
            while randomNumber == 0 && i == 0 {
                randomNumber = arc4random_uniform(10)
            }
            number += "\(randomNumber)"
        }
        return number
    }
    
    
    func registerEmailAlert() {
        button.isHidden = true
        let alert = UIAlertController(title: "Register App", message: "This app is restricted to employees of ForgeRock. Please enter your ForgeRock email address", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
            textField.textAlignment = .center
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in self.checkAppRegister() }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.registerSendCode(email: alert.textFields![0].text!)
        }))
        present(alert, animated: true) {}
    }
    
    
    func registerCodeAlert() {
        let alert = UIAlertController(title: "Register App", message: "Please check your email and enter the registration code", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.text = ""
            textField.textAlignment = .center
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in self.checkAppRegister() }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.registerSendDevice(code:alert.textFields![0].text!)
        }))
        present(alert, animated: true) {}
    }
    
    
    func registerSendCode(email:String) {
        let split = email.split(separator: "@").map{ String($0) }
        if (split.count == 2) && (split[1] == "forgerock.com") {
            registrationCode = generateRandomDigits(8)
            
            let authnUrl = "https://host.mybank.com/banking/ressrvr/device/register?action=register"
            print("authnUrl: \(authnUrl)")
            
            let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
            tokenRequest.httpMethod = "POST"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm a, dd/MM/yyyy"
            
            registerBody = [ "udid":UIDevice.current.identifierForVendor!.uuidString, "code": registrationCode, "email": email, "name": UIDevice.current.name, "registered": dateFormatter.string(from: Date()), "lastseen": dateFormatter.string(from: Date()), "version": Bundle.main.infoDictionary!["CFBundleShortVersionString"]! ]
            
            tokenRequest.httpBody = try? JSONSerialization.data(withJSONObject: registerBody)
            tokenRequest.addValue("application/json", forHTTPHeaderField: "content-type")
            
            URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                data, response, error in
                
                // A client-side error occured
                if error != nil {
                    print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
                }
                
                let responseCode = (response as! HTTPURLResponse).statusCode
                let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                
                if (responseCode == 200) {
                    self.registerCodeAlert()
                } else {
                    self.checkAppRegister()
                }
            }).resume()
        } else {
            checkAppRegister()
        }
    }
    
    
    func registerSendDevice(code:String) {
        if (registrationCode == code) {
            let authnUrl = "https://host.mybank.com/banking/ressrvr/device/register?action=store"
            print("authnUrl: \(authnUrl)")
            
            let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
            tokenRequest.httpMethod = "POST"
            
            tokenRequest.httpBody = try? JSONSerialization.data(withJSONObject: registerBody)
            tokenRequest.addValue("application/json", forHTTPHeaderField: "content-type")

            URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
                data, response, error in
                
                // A client-side error occured
                if error != nil {
                    print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
                }
                
                let responseCode = (response as! HTTPURLResponse).statusCode
                //print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                
                if (responseCode == 200) {
                    let defaults = UserDefaults.standard
                    defaults.set(Date().timeIntervalSince1970, forKey:"registered")
                    defaults.synchronize()
                    DispatchQueue.main.async(execute: {
                        self.button.isHidden = false
                    });
                } else {
                    self.checkAppRegister()
                }
            }).resume()
        }
        else {
            checkAppRegister()
        }
    }
    
}

