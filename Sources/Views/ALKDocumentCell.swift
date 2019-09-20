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
ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol {

    struct CommonPadding {
        
        struct DocumentView {
            static let left: CGFloat = 23
            static let height: CGFloat = 25
            static let width: CGFloat = 26
        }

        struct FileNameLabel {
            static let top: CGFloat = 15
            static let bottom: CGFloat = 15
            static let left: CGFloat = 10
            static let height: CGFloat = 20
        }

        struct DownloadButton {
            static let left: CGFloat = 10
            static let right: CGFloat = 5
            static let height: CGFloat = 27
            static let width: CGFloat = 27
        }
        struct FileTypeView {
            static let bottom: CGFloat = 7
            static let height: CGFloat = 15
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
        let image = UIImage(named: "ic_alk_download", in: Bundle.applozic, compatibleWith: nil)
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
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.ALKSVGreyColor153()
        label.textAlignment = .right
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
        if let _chatGroupID = self.clientChannelKey,
            let _userID = self.viewModel?.contactId,
            let _msgID = self.viewModel?.identifier {
            self.delegateConversationMessageBoxAction?.didMenuAppealClicked(chatGroupHashID:_chatGroupID, userHashID:_userID, messageID:_msgID, message:self.viewModel?.message)
        }
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [bubbleView, frameUIView,downloadButton,fileNameLabel,docImageView,sizeAndFileType,frontView,progressView])

        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(progressView)
        frontView.addGestureRecognizer(longPressGesture)

        let topToOpen = UITapGestureRecognizer(target: self, action: #selector(self.openWKWebView(gesture:)))

        frontView.isUserInteractionEnabled = true
        frontView.addGestureRecognizer(topToOpen)

        downloadButton.addTarget(self, action: #selector(self.downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        docImageView.centerYAnchor.constraint(equalTo: frameUIView.centerYAnchor).isActive = true
        docImageView.leadingAnchor.constraint(equalTo: frameUIView.leadingAnchor, constant: CommonPadding.DocumentView.left).isActive = true
        docImageView.widthAnchor.constraint(equalToConstant: CommonPadding.DocumentView.width).isActive = true
        docImageView.heightAnchor.constraint(equalToConstant: CommonPadding.DocumentView.height).isActive = true

        fileNameLabel.topAnchor.constraint(equalTo: frameUIView.topAnchor, constant: CommonPadding.FileNameLabel.top).isActive = true
        fileNameLabel.leadingAnchor.constraint(equalTo: docImageView.trailingAnchor, constant: CommonPadding.FileNameLabel.left).isActive = true
        fileNameLabel.heightAnchor.constraint(equalToConstant: CommonPadding.FileNameLabel.height).isActive = true
        self.fileNameTrailing = fileNameLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -CommonPadding.DownloadButton.left)
        self.fileNameTrailing?.isActive = true

        downloadButton.centerYAnchor.constraint(equalTo: frameUIView.centerYAnchor).isActive = true
        downloadButton.trailingAnchor.constraint(equalTo: frameUIView.trailingAnchor, constant: -CommonPadding.DownloadButton.right).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.width).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.height).isActive = true

        sizeAndFileType.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor).isActive = true
        sizeAndFileType.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor).isActive = true
        sizeAndFileType.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor).isActive = true
        sizeAndFileType.bottomAnchor.constraint(equalTo: frameUIView.bottomAnchor, constant: -CommonPadding.FileTypeView.bottom).isActive = true
        sizeAndFileType.heightAnchor.constraint(equalToConstant: CommonPadding.FileTypeView.height).isActive = true

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
        return CommonPadding.FileNameLabel.top + CommonPadding.FileNameLabel.height + CommonPadding.FileTypeView.height + CommonPadding.FileTypeView.bottom
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

    func updateView(for state: AttachmentState) {
        switch state {
        case .download:
            downloadButton.isHidden = false
            progressView.isHidden = true
        case .downloaded(let filePath):
            downloadButton.isHidden = true
            progressView.isHidden = true
            viewModel?.filePath = filePath
        case .downloading(let progress, _):
            // show progress bar
            downloadButton.isHidden = true
            progressView.isHidden = false
            progressView.angle = progress
        case .upload:
            downloadButton.isHidden = true
            progressView.isHidden = true
        default:
            print("Not handled")
        }
        
        if downloadButton.isHidden && progressView.isHidden {
            self.fileNameTrailing?.constant = CommonPadding.DownloadButton.left + CommonPadding.DownloadButton.right
        }else{
            self.fileNameTrailing?.constant = -CommonPadding.DownloadButton.left
        }
    }

    private func allowToShowDocument() -> Bool {
        return self.viewModel?.isMyMessage == true || (self.delegateCellRequestInfo?.isEnablePaidFeature() == true && self.viewModel?.isMyMessage == false)
    }
}

extension ALKDocumentCell: ALKHTTPManagerUploadDelegate {

    func dataUploaded(task: ALKUploadTask) {
        print("Data uploaded: \(task.totalBytesUploaded) out of total: \(task.totalBytesExpectedToUpload)")
        let progress = task.totalBytesUploaded.degree(outOf: task.totalBytesExpectedToUpload)
        self.updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        print("Document CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
        if task.uploadError == nil && task.completed == true && task.filePath != nil {
            DispatchQueue.main.async {
                self.updateView(for: .downloaded(filePath: task.filePath ?? ""))
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
