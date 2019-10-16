//
//  ALKSVDocumentMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit
import Foundation
import Applozic

class ALKSVDocumentMessageDetailViewController: ALKSVBaseMessageDetailViewController {

    @IBOutlet weak var imgClipIcon: UIImageView!
    @IBOutlet weak var viewDLKGroup: UIView!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnOpenFile: UIButton!
    @IBOutlet weak var labFileTypeInfo: UILabel!
    @IBOutlet weak var labFileName: UILabel!
    
    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.isHidden = true
        view.clockwise = true
        return view
    }()
    var downloadTapped:((Bool) ->Void)?
    
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
        self.labFileName.text = ALKFileUtils().getFileName(filePath: self.viewModel?.filePath, fileMeta: self.viewModel?.fileMetaInfo)
        let _fileSize = ALKFileUtils().getFileSize(filePath: self.viewModel?.filePath, fileMetaInfo: self.viewModel?.fileMetaInfo) ?? ""
        let _fileType =  ALKFileUtils().getFileExtenion(filePath: self.viewModel?.filePath, fileMeta: self.viewModel?.fileMetaInfo)
        if(!_fileSize.isEmpty) {
            self.labFileTypeInfo.text =  _fileSize + " \u{2022} " + _fileType
        }else{
            self.labFileTypeInfo.text = ""
        }

        guard let state = self.viewModel?.attachmentState() else { return }
        self.updateDownloadView(state: state)
    }

    private func updateDownloadView(state: AttachmentState) {
        switch state {
        case .download:
            self.btnOpenFile.isHidden = true
            self.imgClipIcon.isHidden = true
            self.viewDLKGroup.isHidden = false
            self.btnDownload.isHidden = false
            self.progressView.isHidden = true
            self.labFileTypeInfo.isHidden = false
        case .downloading(let progress, _):
            self.btnOpenFile.isHidden = true
            self.imgClipIcon.isHidden = true
            self.viewDLKGroup.isHidden = false
            self.btnDownload.isHidden = true
            self.progressView.isHidden = false
            self.labFileTypeInfo.isHidden = false
            progressView.angle = progress
        case .downloaded(let filePath):
            self.btnOpenFile.isHidden = false
            self.imgClipIcon.isHidden = false
            self.viewDLKGroup.isHidden = true
            self.btnDownload.isHidden = true
            self.progressView.isHidden = true
            self.labFileTypeInfo.isHidden = true
            viewModel?.filePath = filePath
        default:
            break
        }
    }
}

//MARK: - button control
extension ALKSVDocumentMessageDetailViewController {
    @IBAction func openFileButtonTouchUpInside(_ sender: Any) {
        guard  let filePath = self.viewModel?.filePath, ALKFileUtils().isSupportedFileType(filePath:filePath) else {
            let errorMessage = (self.viewModel?.filePath != nil) ? "File type is not supported":"File is not downloaded"
            print(errorMessage)
            //try to download
            if self.btnDownload.isHidden == false {
                self.downloadButtonTouchUpInside(self.btnDownload)
            }
            return
        }
        
        let docViewController = ALKDocumentViewerController()
        docViewController.filePath = self.viewModel?.filePath ?? ""
        docViewController.fileName = self.viewModel?.fileMetaInfo?.name ?? ""
        let _nagVC = UINavigationController(rootViewController: docViewController)
        _nagVC.modalPresentationStyle = .overCurrentContext
        _nagVC.modalTransitionStyle = .crossDissolve
        self.present(_nagVC, animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTouchUpInside(_ sender: Any) {
        self.downloadTapped?(true)
    }
}

//MARK: - download file control
extension ALKSVDocumentMessageDetailViewController: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        print("Document CELL DATA UPDATED AND FILEPATH IS", viewModel?.filePath ?? "")
        let total = task.totalBytesExpectedToDownload
        let progress = task.totalBytesDownloaded.degree(outOf: total)
        self.updateDownloadView(state: .downloading(progress: progress, totalCount: total))
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
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
