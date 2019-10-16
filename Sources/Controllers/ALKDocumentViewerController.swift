//
//  ALKDocumentViewerController.swift
//  ApplozicSwift
//
//  Created by apple on 13/03/19.
//

import Foundation
import WebKit

class ALKDocumentViewerController : UIViewController,WKNavigationDelegate {

    var webView: WKWebView = WKWebView()
    var fileName: String = ""
    var filePath: String = ""
    var fileUrl : URL = URL(fileURLWithPath: "")

    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButtonNavigation()
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        self.view.bringSubviewToFront(activityIndicator)
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        self.fileUrl = ALKFileUtils().getDocumentDirectory(fileName: filePath)
        activityIndicator.startAnimating()
        webView.loadFileURL(self.fileUrl, allowingReadAccessTo: self.fileUrl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.showShare(_:)))
        self.title =  fileName
    }

    @objc func showShare(_ sender: Any?) {
        let vc = UIActivityViewController(activityItems: [fileUrl], applicationActivities: [])
        self.present(vc, animated: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func addBackButtonNavigation(){
        if self.navigationController?.viewControllers.count == 1 &&
            self.navigationController?.viewControllers.first is ALKDocumentViewerController {
            let _backImage = UIImage.init(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
            navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: _backImage, style: .plain, target: self , action: #selector(backViewAction(_:)))
        }
    }
    
    @objc private func backViewAction(_ sender: UIBarButtonItem) {
        if self.navigationController?.popViewController(animated: true) == nil {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}
