//
//  VerifyView.swift
//  ForgeBank
//
//  Created by Jon Knight on 03/01/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//

import UIKit


class VerifyView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var stage:Int = 0
    var profileImageView:UIImageView? = nil
    var docImageView:UIImageView? = nil
    var msgLabel:UILabel? = nil
    var OKbutton:UIButton? = nil
        
    @IBOutlet weak var mScrollView: UIScrollView!

    
    override func viewDidLoad() {
        print("viewDidLoad: VerifyView")
        super.viewDidLoad()
        self.updateDisplay()
    }
    
    
    func updateDisplay() {
        mScrollView.subviews.map { $0.removeFromSuperview() }
        mScrollView.isScrollEnabled = true
        mScrollView.isUserInteractionEnabled = true
        
        var py:CGFloat = 40
        // Cancel button
        let button = UIButton()
        button.frame = CGRect(x: view.bounds.size.width-40 , y: py, width: 24, height: 24)
        button.layer.cornerRadius = 12
        button.backgroundColor = #colorLiteral(red: 0.5074513555, green: 0.5972354412, blue: 0.8209660053, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 24)
        button.setTitle("\u{f057}", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        mScrollView.addSubview(button)
        
        var label = UILabel()
        label.frame.origin.x = 20
        label.frame.origin.y = py+5
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.font = UIFont(name:"Helvetica-Light", size: 20)
        label.text = "ID VERIFICATION"
        label.sizeToFit()
        mScrollView.addSubview(label)
        
        let hr = UIView()
        hr.frame = CGRect(x: 20, y: CGFloat(py+35), width: self.view.bounds.size.width-40, height: 1)
        hr.backgroundColor = UIColor.orange
        mScrollView.addSubview(hr)
        
        label = UILabel()
        label.frame = CGRect(x: 20, y: Int(py+10), width: Int(view!.bounds.size.width-40), height: 200)
        label.textAlignment = .center
        label.textColor = UIColor.lightGray
        label.font = UIFont(name:"Helvetica-Light", size: 16)
        label.text = "We will try to verify your identity by matching your face against an approved government issued ID document such as a passport or drivers license. Please have this ready."
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        mScrollView.addSubview(label)
        
        var image = UIImage(named: "person")
        profileImageView = UIImageView(image: image)
        profileImageView!.contentMode = UIViewContentMode.scaleAspectFill
        profileImageView!.frame.origin.x = 20
        profileImageView!.frame.origin.y = py+185
        profileImageView!.frame.size.width = (view!.bounds.size.width-60)/2
        profileImageView!.frame.size.height = profileImageView!.frame.size.width * (image!.size.height / image!.size.width)
        profileImageView!.clipsToBounds = true
        profileImageView!.layer.cornerRadius = 20
        profileImageView!.layer.borderWidth = 1
        profileImageView!.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        mScrollView.addSubview(profileImageView!)
        
        image = UIImage(named: "personid")
        docImageView = UIImageView(image: image)
        docImageView!.contentMode = UIViewContentMode.scaleAspectFill
        docImageView!.frame.origin.x = self.view.center.x + 10
        docImageView!.frame.origin.y = CGFloat(py+185)
        docImageView!.frame.size.width = (view!.bounds.size.width-60)/2
        docImageView!.frame.size.height = docImageView!.frame.size.width * (image!.size.height / image!.size.width)
        docImageView!.clipsToBounds = true
        docImageView!.layer.cornerRadius = 20
        docImageView!.layer.borderWidth = 1
        docImageView!.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        mScrollView.addSubview(docImageView!)
        
        py = docImageView!.frame.origin.y + docImageView!.frame.size.height
        msgLabel = UILabel()
        msgLabel!.frame = CGRect(x: 20, y: Int(py+40), width: Int(view!.bounds.size.width-40), height: 200)
        msgLabel!.textAlignment = .center
        msgLabel!.textColor = UIColor.white
        msgLabel!.font = UIFont(name:"Helvetica-Light", size: 16)
        msgLabel!.text = "Please smile at the camera and press the start button to begin."
        msgLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        msgLabel!.numberOfLines = 0
        mScrollView.addSubview(msgLabel!)
        
        // Go button
        OKbutton = UIButton()
        OKbutton!.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        OKbutton!.center.x = self.view.center.x
        OKbutton!.center.y = CGFloat(py + 240)
        OKbutton!.layer.cornerRadius = 30
        OKbutton!.backgroundColor = #colorLiteral(red: 0.5074513555, green: 0.5972354412, blue: 0.8209660053, alpha: 1)
        OKbutton!.setTitleColor(UIColor.white, for: .normal)
        OKbutton!.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 32)
        OKbutton!.setTitle("\u{f144}", for: .normal)
        OKbutton!.addTarget(self, action: #selector(goButtonAction), for: .touchUpInside)
        mScrollView.addSubview(OKbutton!)

        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py+320))
    }
    
    
    func cancelButtonAction(sender: UIButton) {
        self.performSegue(withIdentifier: "VerifiedSegue", sender: self)
    }
    
    
    func goButtonAction() {
        switch stage {
        case 0:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.cameraDevice = .front
                imagePicker.allowsEditing = false
                imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashMode.off
                self.present(imagePicker, animated: true, completion: nil)
            }
        case 1:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        case 2:
            msgLabel!.text = "Scanning images ..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                let hr = UIView()
                hr.frame = CGRect(x: Int(self.profileImageView!.frame.origin.x)+5, y: Int(self.profileImageView!.frame.origin.y)+5, width: Int(self.profileImageView!.frame.width)-10, height: 10)
                hr.backgroundColor = UIColor(red:1, green:0, blue:0, alpha:0.5)
                self.mScrollView.addSubview(hr)
                UIView.animate(withDuration: 2, delay: 0, options: [.autoreverse], animations: {
                    hr.transform = CGAffineTransform(translationX: 0, y: self.profileImageView!.frame.height-15)
                }, completion: { (Bool) in hr.removeFromSuperview() })
                
                let hr2 = UIView()
                hr2.frame = CGRect(x: Int(self.docImageView!.frame.origin.x)+10, y: Int(self.docImageView!.frame.origin.y)+5, width: 10, height: Int(self.profileImageView!.frame.height)-10)
                hr2.backgroundColor = UIColor(red:1, green:0, blue:0, alpha:0.5)
                self.mScrollView.addSubview(hr2)
                UIView.animate(withDuration: 2, delay: 0, options: [.autoreverse], animations: {
                    hr2.transform = CGAffineTransform(translationX: self.profileImageView!.frame.width-25, y: 0)
                }, completion: { (Bool) in hr2.removeFromSuperview() })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.msgLabel!.text = "Congratulations! Photo and document verified.\n\n Please press here to update your account."
                    self.OKbutton!.setTitle("\u{f4fc}", for: .normal)
                    self.profileImageView!.layer.borderColor = #colorLiteral(red: 0, green: 0.7692068219, blue: 0.7163350582, alpha: 1)
                    self.docImageView!.layer.borderColor = #colorLiteral(red: 0, green: 0.7692068219, blue: 0.7163350582, alpha: 1)
                    self.stage = 3
                }
            }
        case 3:
            let image : UIImage = profileImageView!.image!.resizeImage(80, opaque: true)
            let imageData:Data = UIImageJPEGRepresentation(image, 0.8)!
            let imageBase64:String = imageData.base64EncodedString()
            
            let defaults = UserDefaults.standard
            let uid = SessionManager.currentSession.idtoken["sub"].stringValue.lowercased()
            let access_token = SessionManager.currentSession.oauth["access_token"].stringValue
            
            let authnUrl = defaults.string(forKey: "bank_host")! + "/banking/ressrvr/api/" + uid
            
            let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
            tokenRequest.httpMethod = "PUT"
            tokenRequest.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
            tokenRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let jsonBody: [String: Any] = [ "verified": true, "postalAddress": "30 Acacia Avenue", "photo": "data:image/jpeg;base64,"+imageBase64 ]
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
                //print("Authentication: received Response (\(responseCode)): \(String(describing: responseData))")
                
                if (responseCode == 200) {
                    SessionManager.currentSession.refreshRequired = true
                } // JONK ELSE ERROR
                self.performSegue(withIdentifier: "VerifiedSegue", sender: self)
            })
            httpRequest.resume()
        default:
            print("STAGE: too far")
        }
    }

        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        if (stage == 0) {
            profileImageView!.image = image
            msgLabel!.text = "Please position your verification document in front of the camera and press the start button."
            stage = 1
        } else {
            docImageView!.image = image
            stage = 2
            goButtonAction()
        }
    }
 
}
