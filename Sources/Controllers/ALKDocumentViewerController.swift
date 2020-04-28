//
//  ALKDocumentViewerController.swift
//  ApplozicSwift
//
//  Created by apple on 13/03/19.
//

import Foundation
import WebKit
import AVFoundation
import Applozic

protocol ALKDocumentViewerControllerDelegate {
    func refreshDocumentCell(message: ALKMessageViewModel)
}

class ALKDocumentViewerController : UIViewController,WKNavigationDelegate {

    var webView: WKWebView = WKWebView()
    var fileName: String = ""
    var filePath: String = ""
    var fileUrl : URL = URL(fileURLWithPath: "")
    var message: ALKMessageViewModel!
    var delegate:ALKDocumentViewerControllerDelegate?
    
    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpNavigationBar()
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.backgroundColor = UIColor.gray
        activityIndicator.layer.cornerRadius = 5
        view.addSubview(activityIndicator)
        self.view.bringSubviewToFront(activityIndicator)
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        self.reloadWebView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title =  fileName
    }

    @objc func showShare(_ sender: Any?) {
        let vc = UIActivityViewController(activityItems: [fileUrl], applicationActivities: [])
        self.activityIndicator.startAnimating()
        self.present(vc, animated: true) {
            self.activityIndicator.stopAnimating()
        }
    }
    
    @objc func reloadView(_ sender: Any?) {
        let _filePath = self.message.filePath ?? self.filePath
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(_filePath).path
        try? FileManager.default.removeItem(atPath: path)
        //refresh and update view
        self.message.filePath = nil
        //refresh cell
        self.delegate?.refreshDocumentCell(message: self.message)
        self.downloadFile()
    }
    
    func reloadWebView(){
        self.fileUrl = ALKFileUtils().getDocumentDirectory(fileName: self.filePath)
        activityIndicator.startAnimating()
        webView.loadFileURL(self.fileUrl, allowingReadAccessTo: self.fileUrl)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func setUpNavigationBar(){
        self.addBackButtonNavigation()
        //right button
        let _svRightBtnGroup:UIStackView = UIStackView()
        _svRightBtnGroup.alignment = .fill
        _svRightBtnGroup.distribution = .fill
        _svRightBtnGroup.spacing = 8.0
        
        let _btnSize = CGSize(width: 24.0, height: 24.0)
        //share button
        let _shareBtn:UIButton = UIButton(type: .custom)
        _shareBtn.setImage(UIImage(named: "sv_button_share_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        _shareBtn.addTarget(self, action: #selector(self.showShare(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            _shareBtn.heightAnchor.constraint(equalToConstant: _btnSize.height),
            _shareBtn.widthAnchor.constraint(equalToConstant: _btnSize.width)
        ])
        _svRightBtnGroup.addArrangedSubview(_shareBtn)
        
        //refresh button
        let _refreshBtn:UIButton = UIButton(type: .custom)
        _refreshBtn.setImage(UIImage(named: "sv_alk_img_refresh", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        _refreshBtn.addTarget(self, action: #selector(self.reloadView(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            _refreshBtn.heightAnchor.constraint(equalToConstant: _btnSize.height),
            _refreshBtn.widthAnchor.constraint(equalToConstant: _btnSize.width)
        ])
        _svRightBtnGroup.addArrangedSubview(_refreshBtn)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: _svRightBtnGroup)
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

//controller for download
extension ALKDocumentViewerController : ALKHTTPManagerDownloadDelegate{
    
    func downloadFile(){
        self.activityIndicator.startAnimating()
        ALMessageClientService().downloadImageUrl(self.message.fileMetaInfo?.blobKey) { (fileUrl, error) in
            guard error == nil, let fileUrl = fileUrl else {
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: fileUrl, fileName: self.message.fileMetaInfo?.name)
            task.identifier = self.message.identifier
            task.totalBytesExpectedToDownload = self.message.size
            httpManager.downloadAttachment(task: task)
        }
    }
    
    func dataDownloaded(task: ALKDownloadTask) {
        //none
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        self.activityIndicator.stopAnimating()
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            return
        }
        self.filePath = filePath
        self.message?.filePath = filePath
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.reloadWebView()
            self.delegate?.refreshDocumentCell(message:self.message)
        }
    }
}
