//
//  SpinnerView.swift
//  ForgeBank
//
//  Created by Jon Knight on 07/01/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func startSpinner() -> SpinnerView {
        let spinner = SpinnerView()
        addChildViewController(spinner)
        spinner.view.frame = view.frame
        view.addSubview(spinner.view)
        spinner.didMove(toParentViewController: self)
        return spinner
    }
    
    func stopSpinner(spinner:SpinnerView) {
        DispatchQueue.main.async(execute: {
            spinner.willMove(toParentViewController: nil)
            spinner.view.removeFromSuperview()
            spinner.removeFromParentViewController()
        });
    }
}


class SpinnerView: UIViewController {
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
