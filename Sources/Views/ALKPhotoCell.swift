//
//  ALKPhotoCell.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Applozic

protocol AttachmentDelegate {
    func tapAction(message: ALKMessageViewModel)
}

// MARK: - ALKPhotoCell
class ALKPhotoCell: ALKChatBaseCell<ALKMessageViewModel>,
                    ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol {

    var delegate: AttachmentDelegate?

    var photoView: UIImageView = {
        let mv = UIImageView()
        mv.backgroundColor = .clear
        mv.contentMode = .scaleAspectFill
        mv.clipsToBounds = true
        return mv
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor153()
        return lb
    }()

    var fileSizeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor153()
        return lb
    }()

    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    var captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ALKSVPrimaryDarkGrey()
        return label
    }()
    static var maxWidth = UIScreen.main.bounds.width

    // To be changed from the class that is subclassing `ALKPhotoCell`
    class var messageTextFont: UIFont {
        return UIFont.systemFont(ofSize: 16, weight: .medium)
    }

    // This will be used to calculate the size of the photo view.
    static var heightPercentage: CGFloat = 0.5
    static var widthPercentage: CGFloat = 0.48

    struct Padding {
        struct CaptionLabel {
            static var top: CGFloat = 7.0
            static var bottom: CGFloat = 7.0
            static var left: CGFloat = 7.0
            static var right: CGFloat = 7.0
            static var height: CGFloat = 7.0
        }
    }

    var url: URL?

    var uploadTapped:((Bool) ->Void)?
    var uploadCompleted: ((_ responseDict: Any?) ->Void)?

    var downloadTapped:((Bool) ->Void)?
    
    var captionLabelTopConst:NSLayoutConstraint?
    var captionLabelHeightConst:NSLayoutConstraint?
    var captionLabelBottomConst:NSLayoutConstraint?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat) -> CGFloat {

        var height: CGFloat

        height = ceil(width*heightPercentage)
        if let message = viewModel.message, !message.isEmpty {
            height += message.rectWithConstrainedWidth(
                width*widthPercentage,
                font: messageTextFont).height.rounded(.up) + Padding.CaptionLabel.bottom
        }

        return topPadding()+height+bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        activityIndicator.color = .black
        timeLabel.text   = viewModel.time
        captionLabel.text = viewModel.message

        if captionLabel.text?.count ?? 0 > 0 {
            captionLabelTopConst?.constant = Padding.CaptionLabel.top
            captionLabelHeightConst?.constant = Padding.CaptionLabel.height
            captionLabelBottomConst?.constant = -Padding.CaptionLabel.bottom
        }else{
            captionLabelTopConst?.constant = 0
            captionLabelHeightConst?.constant = 0
            captionLabelBottomConst?.constant = 0
        }
        print("Update ViewModel filePath:: %@", viewModel.filePath ?? "")
        guard let state = viewModel.attachmentState() else {
            return
        }
        updateView(for: state)
    }

    @objc func actionTapped(button: UIButton) {
        delegate?.tapAction(message: viewModel!)
    }

    override func setupStyle() {
        super.setupStyle()

        //timeLabel.setStyle(ALKMessageStyle.time)
        fileSizeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        frontView.addGestureRecognizer(longPressGesture)
        uploadButton.isHidden = true
        uploadButton.addTarget(self, action: #selector(ALKPhotoCell.uploadButtonAction(_:)), for: .touchUpInside)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        singleTap.numberOfTapsRequired = 1
        frontView.addGestureRecognizer(singleTap)

        downloadButton.addTarget(self, action: #selector(ALKPhotoCell.downloadButtonAction(_:)), for: .touchUpInside)
        contentView.addViewsForAutolayout(views:
            [frontView,
             photoView,
             bubbleView,
             timeLabel,
             fileSizeLabel,
             captionLabel,
             uploadButton,
             downloadButton,
             activityIndicator])
        contentView.bringSubviewToFront(photoView)
        contentView.bringSubviewToFront(frontView)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(uploadButton)
        contentView.bringSubviewToFront(activityIndicator)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        // CaptionLabel's Bottom Padding calculation:
        //
        // First understand how total view's(ContentView) height is calculated:
        // ContentView => topPadding + PhotoView + CaptionLabel
        //               + captionLabelBottomPadding(if caption is there) + bottomPadding
        //
        // Here's how CaptionLabel's vertical Constraints are calculated:
        // CaptionLabelTop -> PhotoView.top
        //
        // CaptionLabelBottom -> (contentView - bottomPadding) which is equal to
        // (CaptionLabel + captionLabelBottom)
        
        captionLabelTopConst = captionLabel.topAnchor.constraint(
                equalTo: photoView.bottomAnchor,
                constant: Padding.CaptionLabel.top)
        captionLabelTopConst?.isActive = true
        captionLabel.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.CaptionLabel.left).isActive = true
        captionLabel.trailingAnchor.constraint(
                equalTo:bubbleView.trailingAnchor,
                constant: -Padding.CaptionLabel.right).isActive = true
        captionLabelBottomConst = captionLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.CaptionLabel.bottom)
        captionLabelBottomConst?.isActive = true
        captionLabelHeightConst = captionLabel.heightAnchor.constraint(equalToConstant: Padding.CaptionLabel.height)
        captionLabelHeightConst?.isActive = true
    }

    @objc private func downloadButtonAction(_ selector: UIButton) {
        if self.allowToShowPhoto() == false {//is not self message
            self.delegateCellRequestInfo?.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.funcNeedPaid)
            return
        }
        downloadTapped?(true)
    }

    func updateView(for state: AttachmentState) {
        DispatchQueue.main.async {
            self.updateView(state: state)
        }
    }

    private func updateView(state: AttachmentState) {
        switch state {
        case .upload:
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            guard let filePath = viewModel?.filePath else { return }
            let path = docDirPath.appendingPathComponent(filePath)
            setPhotoViewImageFromFileURL(path)
            uploadButton.isHidden = false
        case .uploaded(_):
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
            frontView.isUserInteractionEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        case .uploading(_, _):
            uploadButton.isHidden = true
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
        case .download:
            downloadButton.isHidden = false
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            uploadButton.isHidden = true
            loadThumbnail()
        case .downloading:
            uploadButton.isHidden = true
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
            frontView.isUserInteractionEnabled = false
        case .downloaded(let filePath):
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
            viewModel?.filePath = filePath
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            setPhotoViewImageFromFileURL(path)
            frontView.isUserInteractionEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        }
    }

    func loadThumbnail() {
        guard let message = viewModel, let metadata = message.fileMetaInfo else {
            return
        }
        guard (ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()) else {
            self.photoView.kf.setImage(with: message.thumbnailURL)
            return
        }
        guard let thumbnailPath = metadata.thumbnailFilePath else {
            ALMessageClientService().downloadImageThumbnailUrl(metadata.thumbnailUrl, blobKey: metadata.thumbnailBlobKey) { (url, error) in
                guard error == nil,
                    let url = url
                    else {
                    print("Error downloading thumbnail url")
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
        setThumbnail(thumbnailPath)
    }

    func setImage(imageView: UIImageView, name: String) {
        DispatchQueue.global(qos: .background).async {
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(name)
            do {
                let data = try Data(contentsOf: path)
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            } catch {
                DispatchQueue.main.async {
                    imageView.image = nil
                }
            }
        }
    }

    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateThumbnailPath(_ key: String, filePath: String) {
        let messageKey = ThumbnailIdentifier.removePrefix(from: key)
        let dbMessage = ALMessageDBService().getMessageByKey("key", value: messageKey) as! DB_Message
        dbMessage.fileMetaInfo.thumbnailFilePath = filePath

        let alHandler = ALDBHandler.sharedInstance()
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }

    fileprivate func setThumbnail(_ path: String) {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docDirPath.appendingPathComponent(path)
        setPhotoViewImageFromFileURL(path)
    }

    func menuReply(_ sender: Any) {
        menuAction?(.reply)
    }
    
    func menuAppeal(_ sender: Any) {
        menuAction?(.appeal(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, messageID: self.viewModel?.identifier, message: self.viewModel?.message))
    }

    func menuPinMsg(_ sender: Any) {
        menuAction?(.pinMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, messageID: self.viewModel?.identifier, message: self.viewModel?.message, viewModel: self.viewModel))
    }
    
    func setPhotoViewImageFromFileURL(_ fileURL: URL) {
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        photoView.kf.setImage(with: provider)
    }
    
    private func allowToShowPhoto() -> Bool {
        return self.delegateCellRequestInfo?.isEnablePaidFeature() == true
    }
}

extension ALKPhotoCell: ALKHTTPManagerUploadDelegate {
    func dataUploaded(task: ALKUploadTask) {
        NSLog("Photo cell data uploading started for: %@", viewModel?.filePath ?? "")
        DispatchQueue.main.async {
            print("task filepath:: ", task.filePath ?? "")
            let progress = task.totalBytesUploaded.degree(outOf: task.totalBytesExpectedToUpload)
            self.updateView(for: .uploading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
        }
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        NSLog("Photo cell data uploaded for: %@", viewModel?.filePath ?? "")
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

extension ALKPhotoCell: ALKHTTPManagerDownloadDelegate {
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
            self.updateView(for: .downloading(progress: progress, totalCount: total))
        }
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
            return
        }
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            DispatchQueue.main.async {
                self.setThumbnail(filePath)
            }
            self.updateThumbnailPath(identifier, filePath: filePath)
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
