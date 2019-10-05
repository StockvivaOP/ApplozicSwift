//
//  ALKDocumentCell.swift
//  ApplozicSwift
//
//  Created by Sunil on 05/03/19.
//

import Foundation
import UIKit
import Kingfisher
import Applozic

class ALKDocumentCell:ALKChatBaseCell<ALKMessageViewModel>,
ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol {

    struct CommonPadding {
        
        struct DocumentView {
            static let left: CGFloat = 20
            static let height: CGFloat = 25
            static let width: CGFloat = 26
        }

        struct FileNameLabel {
            static let top: CGFloat = 12
            static let bottom: CGFloat = 12
            static let left: CGFloat = 10
            static let right: CGFloat = 10
            static let height: CGFloat = 20
        }

        struct DownloadButton {
            static let top: CGFloat = 4.0
            static let left: CGFloat = 10
            static let right: CGFloat = 5
            static let height: CGFloat = 24
            static let width: CGFloat = 24
        }
        struct FileTypeView {
            static let bottom: CGFloat = 2
            static let height: CGFloat = 14
            static let width: CGFloat = 56
            static let left: CGFloat = 7.0
            static let right: CGFloat = 7.0
        }
        
        struct AttachBgUIView {
            static let top: CGFloat = 7.0
            static let bottom: CGFloat = 7.0
            static let left: CGFloat = 7.0
            static let right: CGFloat = 7.0
        }
    }

    var uploadTapped:((Bool)->Void)?
    var uploadCompleted: ((_ responseDict: Any?)->Void)?
    var downloadTapped:((Bool)->Void)?

    var docImageView: UIImageView = {
        let imv = UIImageView()
        imv.image =  UIImage(named: "ic_alk_document", in: Bundle.applozic, compatibleWith: nil)
        imv.backgroundColor = .clear
        imv.clipsToBounds = true
        return imv
    }()

    var downloadButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.isUserInteractionEnabled = true
        button.setImage(image, for: .normal)
        return button
    }()
    
    var uploadButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.isUserInteractionEnabled = true
        button.setImage(image, for: .normal)
        return button
    }()
    
    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    var fileNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVPrimaryDarkGrey()
        label.textAlignment = .left
        label.isOpaque = true
        return label
    }()

    var sizeAndFileType: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 9)
        label.textColor = UIColor.ALKSVGreyColor102()
        label.textAlignment = .center
        label.isOpaque = true
        return label
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor153()
        return lb
    }()

    var frameUIView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = UIColor.clear
        return uiView
    }()
    
    var attachBgView: UIImageView = {
        let uiView = UIImageView()
        uiView.image = UIImage.init(named: "temp_chat_attachment_bg", in: Bundle.applozic, compatibleWith: nil)
        uiView.backgroundColor = UIColor.clear
        uiView.tintColor = UIColor.ALKSVGreyColor250()
        return uiView
    }()

    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.isHidden = true
        view.clockwise = true
        return view
    }()

    let frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.backgroundColor = .clear
        return view
    }()

    //MARK: stockviva tag start
    var fileNameTrailing :NSLayoutConstraint?
    
    func menuReply(_ sender: Any) {
        menuAction?(.reply)
    }
    
    func menuAppeal(_ sender: Any) {
        menuAction?(.appeal(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, messageID: self.viewModel?.identifier, message: self.viewModel?.message))
    }
    
    func menuPinMsg(_ sender: Any) {
        menuAction?(.pinMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, messageID: self.viewModel?.identifier, message: self.viewModel?.message, viewModel: self.viewModel))
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [bubbleView, frameUIView, attachBgView, downloadButton, uploadButton, fileNameLabel,docImageView,sizeAndFileType,frontView,progressView])

        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(progressView)
        frontView.addGestureRecognizer(longPressGesture)

        let topToOpen = UITapGestureRecognizer(target: self, action: #selector(self.openWKWebView(gesture:)))

        frontView.isUserInteractionEnabled = true
        frontView.addGestureRecognizer(topToOpen)

        downloadButton.addTarget(self, action: #selector(self.downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)
        uploadButton.addTarget(self, action: #selector(self.uploadButtonAction(_:)), for: UIControl.Event.touchUpInside)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        attachBgView.topAnchor.constraint(equalTo: frameUIView.topAnchor, constant: CommonPadding.AttachBgUIView.top).isActive = true
        attachBgView.bottomAnchor.constraint(equalTo: frameUIView.bottomAnchor, constant: -CommonPadding.AttachBgUIView.bottom).isActive = true
        attachBgView.leftAnchor.constraint(equalTo: frameUIView.leftAnchor, constant: CommonPadding.AttachBgUIView.left).isActive = true
        attachBgView.rightAnchor.constraint(equalTo: frameUIView.rightAnchor, constant: -CommonPadding.AttachBgUIView.right).isActive = true
        
        docImageView.centerYAnchor.constraint(equalTo: attachBgView.centerYAnchor).isActive = true
        docImageView.leadingAnchor.constraint(equalTo: attachBgView.leadingAnchor, constant: CommonPadding.DocumentView.left).isActive = true
        docImageView.widthAnchor.constraint(equalToConstant: CommonPadding.DocumentView.width).isActive = true
        docImageView.heightAnchor.constraint(equalToConstant: CommonPadding.DocumentView.height).isActive = true

        fileNameLabel.topAnchor.constraint(equalTo: attachBgView.topAnchor, constant: CommonPadding.FileNameLabel.top).isActive = true
        fileNameLabel.leadingAnchor.constraint(equalTo: docImageView.trailingAnchor, constant: CommonPadding.FileNameLabel.left).isActive = true
        fileNameLabel.bottomAnchor.constraint(equalTo: attachBgView.bottomAnchor, constant: -CommonPadding.FileNameLabel.bottom).isActive = true
        fileNameLabel.heightAnchor.constraint(equalToConstant: CommonPadding.FileNameLabel.height).isActive = true
        self.fileNameTrailing = fileNameLabel.trailingAnchor.constraint(equalTo: attachBgView.trailingAnchor, constant: -CommonPadding.FileNameLabel.right)
        self.fileNameTrailing?.isActive = true

        downloadButton.topAnchor.constraint(equalTo: attachBgView.topAnchor, constant: CommonPadding.DownloadButton.top).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: docImageView.centerXAnchor).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.width).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.height).isActive = true

        sizeAndFileType.topAnchor.constraint(equalTo: downloadButton.bottomAnchor).isActive = true
        sizeAndFileType.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor).isActive = true
        sizeAndFileType.leadingAnchor.constraint(equalTo: attachBgView.leadingAnchor, constant: CommonPadding.FileTypeView.left).isActive = true
        sizeAndFileType.trailingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor, constant: -CommonPadding.FileTypeView.right).isActive = true
        sizeAndFileType.bottomAnchor.constraint(equalTo: attachBgView.bottomAnchor, constant: -CommonPadding.FileTypeView.bottom).isActive = true
        sizeAndFileType.heightAnchor.constraint(equalToConstant: CommonPadding.FileTypeView.height).isActive = true
        sizeAndFileType.widthAnchor.constraint(lessThanOrEqualToConstant: CommonPadding.FileTypeView.width).isActive = true

        uploadButton.topAnchor.constraint(equalTo: downloadButton.topAnchor).isActive = true
        uploadButton.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalTo: downloadButton.widthAnchor).isActive = true
        uploadButton.widthAnchor.constraint(equalTo: downloadButton.heightAnchor).isActive = true
        
        progressView.topAnchor.constraint(equalTo: downloadButton.topAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor).isActive = true
        progressView.heightAnchor.constraint(equalTo: downloadButton.widthAnchor).isActive = true
        progressView.widthAnchor.constraint(equalTo: downloadButton.heightAnchor).isActive = true

    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        return super.rowHeigh(viewModel: viewModel, width: width)
    }

    @objc func openWKWebView(gesture: UITapGestureRecognizer) {
        if self.allowToShowDocument() == false {//is not self message
            self.delegateCellRequestInfo?.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.funcNeedPaid)
            return
        }
        
        guard  let filePath = self.viewModel?.filePath, ALKFileUtils().isSupportedFileType(filePath:filePath) else {

            let errorMessage = (self.viewModel?.filePath != nil) ? "File type is not supported":"File is not downloaded"
              print(errorMessage)
            //try to download
            if self.downloadButton.isHidden == false {
                self.downloadButtonAction(self.downloadButton)
            }
            return
        }

        let docViewController = ALKDocumentViewerController()
        docViewController.filePath = self.viewModel?.filePath ?? ""
        docViewController.fileName = self.viewModel?.fileMetaInfo?.name ?? ""
        let pushAssist = ALPushAssist()
        pushAssist.topViewController.navigationController?.pushViewController(docViewController, animated: false)
    }

    class func commonHeightPadding() -> CGFloat {
        return CommonPadding.FileNameLabel.top + CommonPadding.FileNameLabel.height + CommonPadding.FileNameLabel.bottom + CommonPadding.FileTypeView.height + CommonPadding.FileTypeView.bottom
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.time

        fileNameLabel.text = ALKFileUtils().getFileName(filePath: viewModel.filePath, fileMeta: viewModel.fileMetaInfo)

        let size = ALKFileUtils().getFileSize(filePath: viewModel.filePath, fileMetaInfo: viewModel.fileMetaInfo) ?? ""

        let fileType =  ALKFileUtils().getFileExtenion(filePath: viewModel.filePath,fileMeta: viewModel.fileMetaInfo)

        if(!size.isEmpty) {
            sizeAndFileType.text =  size + " \u{2022} " + fileType
        }

        guard let state = viewModel.attachmentState() else { return }
        updateView(for: state)
    }

    @objc private func downloadButtonAction(_ selector: UIButton) {
        if self.allowToShowDocument() == false {//is not self message
            self.delegateCellRequestInfo?.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.funcNeedPaid)
            return
        }
        downloadTapped?(true)
    }
    
    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }

    func updateView(for state: AttachmentState) {
        switch state {
        case .download:
            docImageView.isHidden = true
            downloadButton.isHidden = false
            uploadButton.isHidden = true
            progressView.isHidden = true
            sizeAndFileType.isHidden = false
        case .downloaded(let filePath):
            docImageView.isHidden = false
            downloadButton.isHidden = true
            uploadButton.isHidden = true
            progressView.isHidden = true
            sizeAndFileType.isHidden = true
            viewModel?.filePath = filePath
        case .downloading(let progress, _):
            // show progress bar
            docImageView.isHidden = true
            downloadButton.isHidden = true
            uploadButton.isHidden = true
            progressView.isHidden = false
            sizeAndFileType.isHidden = false
            progressView.angle = progress
        case .upload:
            docImageView.isHidden = true
            downloadButton.isHidden = true
            uploadButton.isHidden = false
            progressView.isHidden = true
            sizeAndFileType.isHidden = false
        case .uploading(let progress, _):
            docImageView.isHidden = true
            downloadButton.isHidden = true
            uploadButton.isHidden = true
            progressView.isHidden = false
            sizeAndFileType.isHidden = false
            progressView.angle = progress
        case .uploaded(let filePath):
            docImageView.isHidden = false
            downloadButton.isHidden = true
            uploadButton.isHidden = true
            progressView.isHidden = true
            sizeAndFileType.isHidden = true
            viewModel?.filePath = filePath
        }
    }

    private func allowToShowDocument() -> Bool {
        return self.delegateCellRequestInfo?.isEnablePaidFeature() == true
    }
}

extension ALKDocumentCell: ALKHTTPManagerUploadDelegate {

    func dataUploaded(task: ALKUploadTask) {
        print("Data uploaded: \(task.totalBytesUploaded) out of total: \(task.totalBytesExpectedToUpload)")
        let progress = task.totalBytesUploaded.degree(outOf: task.totalBytesExpectedToUpload)
        self.updateView(for: .uploading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        print("Document CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
        if task.uploadError == nil && task.completed == true && task.filePath != nil {
            DispatchQueue.main.async {
                self.updateView(for: .uploaded(filePath: task.filePath ?? ""))
            }
        } else {
            DispatchQueue.main.async {
                self.updateView(for: .upload)
                //show error
                self.delegateCellRequestInfo?.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.attachmentUploadFailure)
            }
        }
    }
}

extension ALKDocumentCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        print("Document CELL DATA UPDATED AND FILEPATH IS", viewModel?.filePath ?? "")
        let total = task.totalBytesExpectedToDownload
        let progress = task.totalBytesDownloaded.degree(outOf: total)
        self.updateView(for: .downloading(progress: progress, totalCount: total))
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
            DispatchQueue.main.async {
                self.updateView(for: .download)
            }
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
