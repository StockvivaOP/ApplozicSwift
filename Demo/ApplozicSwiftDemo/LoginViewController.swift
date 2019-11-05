//
//  AppLogicLoginViewController.swift
//  applozicswift
//
//  Created by Mukesh Thawani on 11/09/17.
//
//


import UIKit
import Applozic

class LoginViewController: UIViewController {

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var emailId: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        userName.text = "az37"
//        password.text = "18552|1572927096|86907fca6786f782b086f64478abaeff"
//        emailId.text = "oldpig.chu@moleculez.co"
        
        userName.text = "QW3A"
        password.text = "18555|1572927232|5b574ef2c7f094a078977e0f2fe767ac"
        emailId.text = "oldpig.chu@moleculez.co"
        
        // Do any additional setup after loading the view.
        ALUserDefaultsHandler.setUserAuthenticationTypeId(1) // APPLOZIC
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func getStartedBtn(_ sender: AnyObject) {
        let appId = ALChatManager.applicationId
        let alUser : ALUser =  ALUser()

        alUser.applicationId = appId
        
        if(ALChatManager.isNilOrEmpty( self.userName.text as NSString?))
        {
            let alert = UIAlertController(title: "Applozic", message: "Please enter userId ", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        alUser.userId = self.userName.text
        ALUserDefaultsHandler.setUserId(alUser.userId)

        print("userName:: " , alUser.userId)
        if(!((emailId.text?.isEmpty)!)){
             alUser.email = emailId.text
             ALUserDefaultsHandler.setEmailId(alUser.email)
        }

        if (!((password.text?.isEmpty)!)){
            alUser.password = password.text
            ALUserDefaultsHandler.setPassword(alUser.password)
        }
        registerUserToApplozic(alUser: alUser)
    }

    private func registerUserToApplozic(alUser: ALUser) {
        let alChatManager = ALChatManager(applicationKey: ALChatManager.applicationId as NSString)
        alChatManager.connectUser(alUser, completion: {response, error in
            if error == nil {
                NSLog("[REGISTRATION] Applozic user registration was successful: %@ \(String(describing: response?.isRegisteredSuccessfully()))")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController")

                self.present(vc!, animated: false, completion: nil)
            } else {
                NSLog("[REGISTRATION] Applozic user registration error: %@", error.debugDescription)
            }
        })
    }


}


