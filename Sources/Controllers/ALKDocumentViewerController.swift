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
    
    private var btnShare:UIButton = UIButton(type: .custom)
    
    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpNavigationBar()
        self.view.backgroundColor = .white
        activityIndicator.backgroundColor = UIColor.gray
        activityIndicator.layer.cornerRadius = 5
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        self.view.addViewsForAutolayout(views: [webView, activityIndicator])
        
        self.view.bringSubviewToFront(activityIndicator)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            activityIndicator.heightAnchor.constraint(equalToConstant: 50.0),
            activityIndicator.widthAnchor.constraint(equalToConstant: 50.0),
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        self.view.layoutIfNeeded()
        
        self.reloadWebView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title =  fileName
    }

    @objc func showShare(_ sender: Any?) {
        let vc = UIActivityViewController(activityItems: [fileUrl], applicationActivities: [])
        vc.popoverPresentationController?.sourceView = self.btnShare
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
        self.btnShare = UIButton(type: .custom)
        self.btnShare.setImage(UIImage(named: "sv_button_share_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        self.btnShare.addTarget(self, action: #selector(self.showShare(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            self.btnShare.heightAnchor.constraint(equalToConstant: _btnSize.height),
            self.btnShare.widthAnchor.constraint(equalToConstant: _btnSize.width)
        ])
        self.btnShare.tintColor = .white
        _svRightBtnGroup.addArrangedSubview(self.btnShare)
        
        //refresh button
        let _refreshBtn:UIButton = UIButton(type: .custom)
        _refreshBtn.setImage(UIImage(named: "sv_alk_img_refresh", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        _refreshBtn.addTarget(self, action: #selector(self.reloadView(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            _refreshBtn.heightAnchor.constraint(equalToConstant: _btnSize.height),
            _refreshBtn.widthAnchor.constraint(equalToConstant: _btnSize.width)
        ])
        _refreshBtn.tintColor = .white
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
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload -  ALKSVMessagePhotoDownloader downloadPhoto with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), msg_key:\(self.message.identifier), msg:\(self.message.rawModel?.dictionary() ?? ["nil":"nil"])")
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
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKDocumentViewerController - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKDocumentViewerController - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        self.filePath = filePath
        self.message?.filePath = filePath
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.reloadWebView()
            self.delegate?.refreshDocumentCell(message:self.message)
        }
    }
}
