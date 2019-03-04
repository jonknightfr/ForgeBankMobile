//
//  AppDelegate.swift
//

import UIKit


extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}


extension String {
    func base64UrlDecode() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    func base64Convert() -> UIImage{
        if (self.isEmpty) {
            return #imageLiteral(resourceName: "face")
        }else {
            // !!! Separation part is optional, depends on your Base64String !!!
            let temp = self.components(separatedBy: ",")
            if let decodedData = Data(base64Encoded: temp[1], options: .ignoreUnknownCharacters) {
                let image = UIImage(data: decodedData)
                return image!
            }
            return UIImage()
        }
    }
    
    func currency() -> String {
        let amount = NSNumber(value: Float(self)!)
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        return currencyFormatter.string(from: amount)!
    }
}


extension UIImage {
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIViewContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width/size.height
        
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
            
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        return newImage
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let userDefaults = UserDefaults.standard
        
        if let storedValue = userDefaults.object(forKey: "bank_host") as? String {
            print("Got stored settings: \(storedValue)")
        } else {
            print("Can't find stored settings, creating defaults.")
            userDefaults.set("https://host.mybank.com", forKey:"bank_host")
            userDefaults.set("forgebank://oidc_callback", forKey:"redirect_uri")
            userDefaults.set("mobileapp", forKey:"client_id")
            userDefaults.set("SECRET", forKey:"client_secret")
            userDefaults.set("REST Login", forKey:"web_login")
            userDefaults.set(true, forKey: "oneTouchLogin")
            userDefaults.synchronize()
         }
        
        if userDefaults.object(forKey: "UDID") == nil {
            let UUID = Foundation.UUID().uuidString
            userDefaults.set(UUID, forKey: "UDID")
            userDefaults.synchronize()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        // If the callback was for the OpenID Connect authentication, then handle the response
        let baseUrl = url.absoluteString.components(separatedBy: "?")[0]
        let defaults = UserDefaults.standard
        let app_redirect_uri = defaults.string(forKey: "redirect_uri")!

        if baseUrl.lowercased() == app_redirect_uri.lowercased() {
            
            // Close the SFSafariViewController
            window!.rootViewController?.presentedViewController?.dismiss(animated: true , completion: nil)
            
            var returnDictionary = [String: String]()
            let queryParams = url.absoluteString.components(separatedBy: "?")[1]
            for queryParam in (queryParams.components(separatedBy: "&")) {
                //print("Parsing query parameter: \(queryParam)")
                var queryElement = queryParam.components(separatedBy: "=")
                returnDictionary[queryElement[0]] = queryElement[1]
            }
            if (returnDictionary["code"] != nil) {
                //print("CODE: " + returnDictionary["code"]!)
                SessionManager.currentSession.getAccessToken(returnDictionary["code"]!, completionHandler: gotAccessToken)
            }
        }
        return true
    }

    
    func gotAccessToken() {
        let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "BankPageViewController") as UIViewController
        DispatchQueue.main.async(execute: {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = initialViewControlleripad
            self.window?.makeKeyAndVisible()
        });
    }

}

