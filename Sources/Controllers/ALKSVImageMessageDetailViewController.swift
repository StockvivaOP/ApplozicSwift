//
//  ALKSVImageMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit
import Foundation
import Applozic
import Kingfisher

class ALKSVImageMessageDetailViewController: ALKSVBaseMessageDetailViewController {

    @IBOutlet weak var imgMessageFile: UIImageView!
    @IBOutlet weak var tvCaptionContent: ALKTextView!
    @IBOutlet weak var viewDLKGroup: UIView!
    @IBOutlet weak var viewDLKIndicatorGroup: UIView!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var imgDownloadIndicator: UIImageView!
    
    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.isHidden = true
        view.clockwise = true
        return view
    }()
    
    var downloadTapped:((Bool) ->Void)?
    var imageFileUpdateDelegate:ALKMediaViewerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up view
        self.setUpView()
        //update content
        self.updateContent()
    }
    
    func setUpView(){
        self.viewDLKGroup.isHidden = true
        
        self.viewDLKGroup.addViewsForAutolayout(views: [self.progressView])
        self.progressView.topAnchor.constraint(equalTo: self.viewDLKGroup.topAnchor)
        self.progressView.leadingAnchor.constraint(equalTo: self.viewDLKGroup.leadingAnchor)
        self.progressView.trailingAnchor.constraint(equalTo: self.viewDLKGroup.trailingAnchor)
        self.progressView.bottomAnchor.constraint(equalTo: self.viewDLKGroup.bottomAnchor)
    }
    
    func updateContent(){
        self.tvCaptionContent.text = self.viewModel?.message ?? ""
        self.tvCaptionContent.isHidden = self.tvCaptionContent.text.count > 0
        
        guard let state = self.viewModel?.attachmentState() else {
            return
        }
        self.updateDownloadView(state: state)
    }
    
    private func updateDownloadView(state: AttachmentState) {
        switch state {
        case .download:
            self.viewDLKGroup.isHidden = false
            self.viewDLKIndicatorGroup.isHidden = self.viewDLKGroup.isHidden
            self.btnDownload.isHidden = false
            self.imgDownloadIndicator.isHidden = self.btnDownload.isHidden
            self.progressView.isHidden = true
            self.loadThumbnail()
        case .downloading(let progress, _):
            self.viewDLKGroup.isHidden = false
            self.viewDLKIndicatorGroup.isHidden = self.viewDLKGroup.isHidden
            self.btnDownload.isHidden = true
            self.imgDownloadIndicator.isHidden = self.btnDownload.isHidden
            self.progressView.isHidden = false
            self.progressView.angle = progress
        case .downloaded(let filePath):
            self.viewDLKGroup.isHidden = true
            self.viewDLKIndicatorGroup.isHidden = self.viewDLKGroup.isHidden
            self.btnDownload.isHidden = true
            self.imgDownloadIndicator.isHidden = self.btnDownload.isHidden
            self.progressView.isHidden = true
            viewModel?.filePath = filePath
            self.self.setPhotoViewImage(path:filePath)
        default:
            break
        }
    }
}

//MARK: - button control
extension ALKSVImageMessageDetailViewController {
    @IBAction func imageViewTouchUpInside(_ sender: Any) {
        let storyboard = UIStoryboard.name(
            storyboard: UIStoryboard.Storyboard.mediaViewer,
            bundle: Bundle.applozic)
        guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
        let vc = nav.viewControllers.first as? ALKMediaViewerViewController
        guard let _messageModel = self.viewModel else { return }
        vc?.delegate = self
        vc?.viewModel = ALKMediaViewerViewModel(
            messages: [_messageModel],
            currentIndex: 0,
            localizedStringFileName: self.configuration.localizedStringFileName)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTouchUpInside(_ sender: Any) {
        self.downloadTapped?(true)
    }
}

//MARK: - image file update
extension ALKSVImageMessageDetailViewController : ALKMediaViewerViewControllerDelegate{
    func refreshMediaCell(message: ALKMessageViewModel) {
        self.viewModel = message
        self.updateContent()
        self.imageFileUpdateDelegate?.refreshMediaCell(message: message)
    }
}

//MARK: - download image control
extension ALKSVImageMessageDetailViewController : ALKHTTPManagerDownloadDelegate {
    func loadThumbnail() {
        guard let message = viewModel, let metadata = message.fileMetaInfo else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - loadThumbnail missing value, msg_key:\(viewModel?.identifier ?? "nil"), msg:\(viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
            return
        }
        guard (ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()) else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - loadThumbnail not enable 'isS3StorageServiceEnabled' or 'isGoogleCloudServiceEnabled', url:\(metadata.thumbnailUrl ?? "nil"), msg_key:\(message.identifier), msg:\(message.rawModel?.dictionary() ?? ["nil":"nil"])")
            self.imgMessageFile.kf.setImage(with: message.thumbnailURL)
            return
        }
        guard let thumbnailPath = metadata.thumbnailFilePath else {
            ALMessageClientService().downloadImageThumbnailUrl(metadata.thumbnailUrl, blobKey: metadata.thumbnailBlobKey) { (url, error) in
                guard error == nil,
                    let url = url
                    else {
                        print("Error downloading thumbnail url")
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - loadThumbnail with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), url:\(metadata.thumbnailUrl ?? "nil"), msg_key:\(message.identifier), msg:\(message.rawModel?.dictionary() ?? ["nil":"nil"])")
                        return
                }
                let httpManager = ALKHTTPManager()
                httpManager.downloadDelegate = self
                let task = ALKDownloadTask(downloadUrl: url, fileName: metadata.name)
                task.identifier = ThumbnailIdentifier.addPrefix(to: message.identifier)
                httpManager.downloadAttachment(task: task)
            }
            return
        }
        self.setPhotoViewImage(path:thumbnailPath)
    }
    
    fileprivate func updateThumbnailPath(_ key: String, filePath: String) {
        let messageKey = ThumbnailIdentifier.removePrefix(from: key)
        guard let dbMessage = ALMessageDBService().getMessageByKey("key", value: messageKey) as? DB_Message else {
            return
        }
        dbMessage.fileMetaInfo.thumbnailFilePath = filePath
        let alHandler = ALDBHandler.sharedInstance()
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }
    
    fileprivate func setPhotoViewImage(path: String) {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docDirPath.appendingPathComponent(path)
        setPhotoViewImageFromFileURL(path)
    }
    
    func setPhotoViewImageFromFileURL(_ fileURL: URL) {
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        self.imgMessageFile.kf.setImage(with: provider)
    }
    
    //MARK: - ALKHTTPManagerDownloadDelegate
    func dataDownloaded(task: ALKDownloadTask) {
        NSLog("Image Bytes downloaded: %i", task.totalBytesDownloaded)
        guard
            let identifier = task.identifier,
            !ThumbnailIdentifier.hasPrefix(in: identifier)
            else {
                return
        }
        DispatchQueue.main.async {
            let total = task.totalBytesExpectedToDownload
            let progress = task.totalBytesDownloaded.degree(outOf: total)
            self.updateDownloadView(state: .downloading(progress: progress, totalCount: total))
        }
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            DispatchQueue.main.async {
                self.setPhotoViewImage(path:filePath)
            }
            self.updateThumbnailPath(identifier, filePath: filePath)
            return
        }
        
        //check can open or not
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(filePath).path
        if UIImage(contentsOfFile: path) == nil {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVImageMessageDetailViewController - dataDownloadingFinished with wrong file format, filePath:\(filePath ), msg_key:\(identifier)")
            try? FileManager.default.removeItem(atPath: path)
            //update view
            DispatchQueue.main.async {
                self.updateDownloadView(state: .download)
            }
            return
        }
        
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateDownloadView(state: .downloaded(filePath: filePath))
        }
    }
}
