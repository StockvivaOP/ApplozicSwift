//
//  ALBaseNavigationController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
public class ALKBaseNavigationViewController: UINavigationController {

    static var statusBarStyle: UIStatusBarStyle = .lightContent

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setNeedsStatusBarAppearanceUpdate()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return ALKBaseNavigationViewController.statusBarStyle
    }

}

extension ALKBaseNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
