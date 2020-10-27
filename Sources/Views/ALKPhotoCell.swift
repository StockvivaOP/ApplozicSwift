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
    func didDownloadImageFailure()
}

// MARK: - ALKPhotoCell
class ALKPhotoCell: ALKChatBaseCell<ALKMessageViewModel>,
                    ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol, ALKDeleteMsgMenuItemProtocol, ALKBookmarkMsgMenuItemProtocol {

    var delegate: AttachmentDelegate?

    var photoView: UIImageView = {
        let mv = UIImageView()
        mv.backgroundColor = .lightGray
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

    fileprivate var downloadButtonClickArea: UIButton = {
        let button = UIButton(type: .custom)
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
    
    var uploadButtonClickArea: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    //tag: stockviva start
    var replyView: ALKImageView = {
        let view = ALKImageView()
        view.backgroundColor = UIColor.clear
        view.tintColor = UIColor.ALKSVGreyColor250()
        view.isUserInteractionEnabled = true
        return view
    }()

    var replyIndicatorView: ALKImageView = {
        let view = ALKImageView()
        view.clipsToBounds = true
        view.isOpaque = true
        view.backgroundColor = UIColor.ALKSVOrangeColor()
        view.tintColor = UIColor.ALKSVOrangeColor()
        view.contentMode = .scaleToFill
        return view
    }()
    
    var replyNameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        label.numberOfLines = 1
        return label
    }()
    
    let replyMessageTypeImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var replyMessageLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVGreyColor102()
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let previewImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var selfNameText: String = {
        let text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_you") ?? localizedString(forKey: "You", withDefaultValue: SystemMessage.LabelName.You, fileName: localizedStringFileName)
        return text
    }()
    
    var replyViewAction: (()->())? = nil
    
    var replyMessageTypeImagewidthConst:NSLayoutConstraint?
    var replyMessageLabelConst:NSLayoutConstraint?
    //tag: stockviva end

    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    var captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ALKSVPrimaryDarkGrey()
        return label
    }()
    
    var adminMsgDisclaimerLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 8)
        lb.textAlignment = .left
        lb.textColor = UIColor.ALKSVGreyColor102()
        return lb
    }()
    
    lazy var adminMsgDisclaimerLabelHeightConst:NSLayoutConstraint? = self.adminMsgDisclaimerLabel.heightAnchor.constraint(equalToConstant: 0)
    var adminMsgDisclaimerLabelBottomConst:NSLayoutConstraint?
    
    static var maxWidth = UIScreen.main.bounds.width

    // To be changed from the class that is subclassing `ALKPhotoCell`
    class var messageTextFont: UIFont {
        return UIFont.systemFont(ofSize: 16, weight: .medium)
    }

    // This will be used to calculate the size of the photo view.
    static var heightPercentage: CGFloat = 0.5
    static var widthPercentage: CGFloat = 0.67

    struct Padding {
        struct CaptionLabel {
            static var top: CGFloat = 7.5
            static var bottom: CGFloat = 7.5
            static var left: CGFloat = 6.0
            static var right: CGFloat = 6.0
            static var height: CGFloat = 7.0
        }
        
        struct AdminMsgDisclaimerLabel {
            static let top: CGFloat = 7.5
            static let bottom: CGFloat = 7.5
            static let left: CGFloat = 6.0
            static let right: CGFloat = 6.0
            static let height: CGFloat = 11.0
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

    class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat,
        replyMessage: ALKMessageViewModel?) -> CGFloat {

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
        self.photoView.image = nil
        activityIndicator.color = .black
        timeLabel.text   = viewModel.date.toConversationViewDateFormat() //viewModel.time
        captionLabel.text = viewModel.message

        if captionLabel.text?.count ?? 0 > 0 {
            //captionLabelTopConst?.constant = Padding.CaptionLabel.top
            captionLabelHeightConst?.constant = Padding.CaptionLabel.height
            captionLabelBottomConst?.constant = Padding.CaptionLabel.bottom
        }else{
            //captionLabelTopConst?.constant = 0
            captionLabelHeightConst?.constant = 0
            captionLabelBottomConst?.constant = 0
        }
        print("Update ViewModel filePath:: %@", viewModel.filePath ?? "")
        guard let state = viewModel.attachmentState() else {
            return
        }
        updateView(for: state)
    }
    
    func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        self.update(viewModel: viewModel)
        
        let _isDeletedMsg = viewModel.getDeletedMessageInfo().isDeleteMessage
        if let replyMessage = replyMessage, _isDeletedMsg == false {
            replyNameLabel.text = replyMessage.isMyMessage ?
                selfNameText : replyMessage.displayName
            replyMessageLabel.text = replyMessage.message
            //update reply icon
            if replyMessage.messageType == ALKMessageType.voice  {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_audio_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_audio") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.video {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_video_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_video") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.photo {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_photo_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.document {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_file_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_document") ?? replyMessageLabel.text
            }else{
                replyMessageTypeImageView.image = nil
            }
            
            ReplyMessageImage().loadPreviewFor(message: replyMessage) { (url, image) in
                var _tempModel = replyMessage
                _tempModel.saveImageThumbnailURLInMetaData(url: url?.absoluteString)
                self.delegateCellRequestInfo?.updateMessageModelData(messageModel: _tempModel, isUpdateView: false)
                if let url = url {
                    self.setImageFrom(url: url, to: self.previewImageView)
                } else {
                    self.previewImageView.image = image
                }
            }
        } else {
            replyNameLabel.text = ""
            replyMessageLabel.text = ""
            replyMessageTypeImageView.image = nil
            previewImageView.image = nil
        }
        
        if replyMessageTypeImageView.image == nil {
            replyMessageTypeImagewidthConst?.constant = 0
            replyMessageLabelConst?.constant = 0
        }else{
            replyMessageTypeImagewidthConst?.constant = 20
            replyMessageLabelConst?.constant = 5
        }
        if viewModel.isMyMessage {
            replyNameLabel.textColor = UIColor.ALKSVOrangeColor()
            replyView.image = setReplyViewImage(isReceiverSide: false)
            replyIndicatorView.image = UIImage.init(named: "sv_button_chatroom_reply_orange", in: Bundle.applozic, compatibleWith: nil)
            replyIndicatorView.backgroundColor = UIColor.clear
            replyIndicatorView.tintColor = UIColor.ALKSVOrangeColor()
        }else{
            replyNameLabel.textColor = UIColor.ALKSVOrangeColor()
            replyView.image = setReplyViewImage(isReceiverSide: true)
            replyIndicatorView.backgroundColor = UIColor.ALKSVOrangeColor()
            replyIndicatorView.tintColor = UIColor.ALKSVOrangeColor()
            replyIndicatorView.image = nil
        }
        
        if _isDeletedMsg {
            self.isHiddenAdminDisclaimer(true)
        }else{
            self.isHiddenAdminDisclaimer( ALKConfiguration.delegateConversationRequestInfo?.isHiddenMessageAdminDisclaimerLabel(viewModel: viewModel) ?? true)
        }
        
        //set color
        let _contactID:String? = replyMessage?.getMessageReceiverHashId()
        if let _messageUserId = _contactID,
            let _userColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            replyNameLabel.textColor = _userColor
            replyIndicatorView.backgroundColor = _userColor
            replyIndicatorView.tintColor = _userColor
        }
        
        
    }

    @objc func actionTapped(button: UIButton) {
        delegate?.tapAction(message: viewModel!)
    }

    override func setupStyle() {
        super.setupStyle()

        //timeLabel.setStyle(ALKMessageStyle.time)
        fileSizeLabel.setStyle(ALKMessageStyle.time)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.photoView.image = nil
        self.photoView.kf.cancelDownloadTask()
        self.previewImageView.image = nil
        self.previewImageView.kf.cancelDownloadTask()
    }
    
    override func setupViews() {
        super.setupViews()
        frontView.addGestureRecognizer(longPressGesture)
        uploadButton.isHidden = true
        uploadButtonClickArea.isHidden = uploadButton.isHidden
        uploadButtonClickArea.addTarget(self, action: #selector(ALKPhotoCell.uploadButtonAction(_:)), for: .touchUpInside)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        singleTap.numberOfTapsRequired = 1
        frontView.addGestureRecognizer(singleTap)

        downloadButtonClickArea.addTarget(self, action: #selector(ALKPhotoCell.downloadButtonAction(_:)), for: .touchUpInside)
        contentView.addViewsForAutolayout(views:
            [frontView,
             photoView,
             bubbleView,
             replyView,
             replyIndicatorView,
             replyNameLabel,
             replyMessageTypeImageView,
             replyMessageLabel,
             previewImageView,
             timeLabel,
             fileSizeLabel,
             captionLabel,
             uploadButton,
             uploadButtonClickArea,
             downloadButton,
             downloadButtonClickArea,
             activityIndicator,
             adminMsgDisclaimerLabel])
        contentView.bringSubviewToFront(photoView)
        contentView.bringSubviewToFront(frontView)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(downloadButtonClickArea)
        contentView.bringSubviewToFront(uploadButton)
        contentView.bringSubviewToFront(uploadButtonClickArea)
        contentView.bringSubviewToFront(activityIndicator)
        contentView.bringSubviewToFront(replyView)
        contentView.bringSubviewToFront(replyIndicatorView)
        contentView.bringSubviewToFront(replyNameLabel)
        contentView.bringSubviewToFront(replyMessageTypeImageView)
        contentView.bringSubviewToFront(replyMessageLabel)
        contentView.bringSubviewToFront(previewImageView)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true

        uploadButtonClickArea.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        uploadButtonClickArea.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        uploadButtonClickArea.leadingAnchor.constraint(equalTo: photoView.leadingAnchor).isActive = true
        uploadButtonClickArea.trailingAnchor.constraint(equalTo: photoView.trailingAnchor).isActive = true
        
        downloadButtonClickArea.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        downloadButtonClickArea.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        downloadButtonClickArea.leadingAnchor.constraint(equalTo: photoView.leadingAnchor).isActive = true
        downloadButtonClickArea.trailingAnchor.constraint(equalTo: photoView.trailingAnchor).isActive = true
        
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
                equalTo: self.adminMsgDisclaimerLabel.topAnchor,
                constant: Padding.CaptionLabel.bottom)
        captionLabelBottomConst?.isActive = true
        captionLabelHeightConst = captionLabel.heightAnchor.constraint(equalToConstant: Padding.CaptionLabel.height)
        captionLabelHeightConst?.isActive = true
        
        self.adminMsgDisclaimerLabelHeightConst?.isActive = true
        self.adminMsgDisclaimerLabelBottomConst = self.adminMsgDisclaimerLabel.bottomAnchor.constraint(
            equalTo: bubbleView.bottomAnchor,
            constant: -Padding.AdminMsgDisclaimerLabel.bottom)
        self.adminMsgDisclaimerLabelBottomConst?.isActive = true
        self.adminMsgDisclaimerLabel.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.AdminMsgDisclaimerLabel.left).isActive = true
        self.adminMsgDisclaimerLabel.trailingAnchor.constraint(
                equalTo:bubbleView.trailingAnchor,
                constant: -Padding.AdminMsgDisclaimerLabel.right).isActive = true
        
        //tag: stockviva start
        let replyTapGesture = UITapGestureRecognizer(target: self, action: #selector(replyViewTapped))
        replyView.addGestureRecognizer(replyTapGesture)
        //tag: stockviva end
    }

    @objc private func downloadButtonAction(_ selector: UIButton) {
        if self.allowToShowPhoto() == false {//is not self message
            self.delegateCellRequestInfo?.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.funcNeedPaid)
            return
        }
        downloadTapped?(true)
    }

    func updateView(for state: AttachmentState) {
        //DispatchQueue.main.async {
            self.updateView(state: state)
        //}
    }
    
    override func isMyMessage() -> Bool {
        return self.viewModel?.isMyMessage ?? false
    }
    
    override func isAdminMessage() -> Bool {
        return self.delegateCellRequestInfo?.isAdminUserMessage(userHashId: self.viewModel?.contactId) ?? false
    }
    
    override func isDeletedMessage() -> Bool {
        return self.viewModel?.getDeletedMessageInfo().isDeleteMessage ?? false
    }
    
    override func canDeleteMessage() -> Bool {
        return self.viewModel?.isAllowToDeleteMessage(self.systemConfig?.expireSecondForDeleteMessage) ?? false
    }

    private func updateView(state: AttachmentState) {
        switch state {
        case .upload:
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            downloadButtonClickArea.isHidden = downloadButton.isHidden
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            guard let filePath = viewModel?.filePath else { return }
            let path = docDirPath.appendingPathComponent(filePath)
            setPhotoViewImageFromFileURL(path)
            uploadButton.isHidden = false
            uploadButtonClickArea.isHidden = uploadButton.isHidden
        case .uploaded(_):
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
            frontView.isUserInteractionEnabled = true
            uploadButton.isHidden = true
            uploadButtonClickArea.isHidden = uploadButton.isHidden
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            downloadButtonClickArea.isHidden = downloadButton.isHidden
        case .uploading(_, _):
            uploadButton.isHidden = true
            uploadButtonClickArea.isHidden = uploadButton.isHidden
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
            downloadButtonClickArea.isHidden = downloadButton.isHidden
        case .download:
            downloadButton.isHidden = false
            downloadButtonClickArea.isHidden = downloadButton.isHidden
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            uploadButton.isHidden = true
            uploadButtonClickArea.isHidden = uploadButton.isHidden
            loadThumbnail()
        case .downloading:
            uploadButton.isHidden = true
            uploadButtonClickArea.isHidden = uploadButton.isHidden
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
            downloadButtonClickArea.isHidden = downloadButton.isHidden
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
            uploadButtonClickArea.isHidden = uploadButton.isHidden
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            downloadButtonClickArea.isHidden = downloadButton.isHidden
        }
    }

    func loadThumbnail() {
        guard let message = viewModel, let metadata = message.fileMetaInfo else {
            return
        }
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            if #available(iOS 11.0, *) {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
                if let capacity = values.volumeAvailableCapacityForImportantUsage {
                    debugPrint("Available capacity for important usage: \(capacity)")
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - downloadAttachment check disk space:\(capacity.description)")
                } else {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - downloadAttachment check disk space: Capacity is unavailable")
                    
                }
            } else {
                // Fallback on earlier versions
            }
        } catch {
             ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - downloadAttachment check disk space error retrieving capacity:  \(error.localizedDescription)")
            
        }
        guard (ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()) else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKPhotoCell - loadThumbnail not enable 'isS3StorageServiceEnabled' or 'isGoogleCloudServiceEnabled', url:\(metadata.thumbnailUrl ?? "nil"), msg_key:\(message.identifier), msg:\(message.rawModel?.dictionary() ?? ["nil":"nil"])")
            self.photoView.kf.setImage(with: message.thumbnailURL)
            return
        }
        guard let thumbnailPath = metadata.thumbnailFilePath else {
            ALMessageClientService().downloadImageThumbnailUrl(metadata.thumbnailUrl, blobKey: metadata.thumbnailBlobKey) { (url, error) in
                guard error == nil,
                    let url = url
                    else {
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKPhotoCell - loadThumbnail with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), url:\(message.fileMetaInfo?.thumbnailUrl ?? "nil"), msg_key:\(message.identifier), msg:\(message.rawModel?.dictionary() ?? ["nil":"nil"])")
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

    fileprivate func setThumbnail(_ path: String) {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docDirPath.appendingPathComponent(path)
        setPhotoViewImageFromFileURL(path)
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch self {
        case let menuItem as ALKPinMsgMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.getSVMessageStatus() != .sent {
                return false
            }
            return super.canPerformAction(action, withSender: sender)
        case let menuItem as ALKReplyMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.getSVMessageStatus() != .sent {
                return false
            }
            return super.canPerformAction(action, withSender: sender)
        case let menuItem as ALKAppealMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.getSVMessageStatus() != .sent {
                return false
            }
            return super.canPerformAction(action, withSender: sender)
        case let menuItem as ALKDeleteMsgMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.getSVMessageStatus() != .sent {
                return false
            }
            return self.canDeleteMessage()
        case let menuItem as ALKBookmarkMsgMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.getSVMessageStatus() != .sent {
                return false
            }
            return super.canPerformAction(action, withSender: sender)
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    func menuReply(_ sender: Any) {
        menuAction?(.reply(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
    }
    
    func menuAppeal(_ sender: Any) {
        menuAction?(.appeal(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
    }

    func menuPinMsg(_ sender: Any) {
        menuAction?(.pinMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
    }
    
    func menuDeleteMsg(_ sender: Any){
        menuAction?(.deleteMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
    }
    
    func menuBookmarkMsg(_ sender: Any){
        menuAction?(.bookmarkMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
    }
    
    func setPhotoViewImageFromFileURL(_ fileURL: URL) {
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        photoView.kf.setImage(with: provider)
    }
    
    private func allowToShowPhoto() -> Bool {
        return self.delegateCellRequestInfo?.isEnablePaidFeature() == true
    }
    
    //tag: stockviva start
    private func setImageFrom(url: URL?, to imageView: UIImageView) {
        guard let url = url else { return }
        let provider = LocalFileImageDataProvider(fileURL: url)
        imageView.kf.setImage(with: provider)
    }
    
    @objc func replyViewTapped() {
        replyViewAction?()
    }
    
    static func getReplyViewHeight(_ defaultReplyViewHeight:CGFloat = 0, defaultMsgHeight:CGFloat = 0, maxMsgHeight:CGFloat, maxMsgWidth:CGFloat, replyMessageContent:String?) -> (replyViewHeight:CGFloat, replyMsgViewHeight:CGFloat, offsetOfMsgIncreaseHeight:CGFloat){
        
        let _tempLabel:UILabel = UILabel(frame: CGRect.zero)
        _tempLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        _tempLabel.textColor = UIColor.ALKSVGreyColor102()
        _tempLabel.numberOfLines = 3
        _tempLabel.lineBreakMode = .byTruncatingTail
        _tempLabel.text = replyMessageContent
        
        var _resultMsgHeight:CGFloat = _tempLabel.sizeThatFits(CGSize(width: maxMsgWidth, height: maxMsgHeight) ).height
        if _resultMsgHeight < defaultMsgHeight {
            _resultMsgHeight = defaultMsgHeight
        }
        let _offsetOfMsgIncreaseHeight = (_resultMsgHeight - defaultMsgHeight)
        var _replyViewViewHeight = defaultReplyViewHeight + _offsetOfMsgIncreaseHeight
        if _replyViewViewHeight < defaultReplyViewHeight {
            _replyViewViewHeight = defaultReplyViewHeight
        }
        return (replyViewHeight:_replyViewViewHeight, replyMsgViewHeight:_resultMsgHeight, offsetOfMsgIncreaseHeight:_offsetOfMsgIncreaseHeight)
    }
    
    func updateBubbleViewImage(for style: ALKMessageStyle.BubbleStyle, isReceiverSide: Bool = false, showHangOverImage:Bool) {
        bubbleView.image = setBubbleViewImage(for: style, isReceiverSide: isReceiverSide, showHangOverImage: showHangOverImage)
        
        if self.isMyMessage() {
            bubbleView.tintColor = UIColor.messageBox.my()
            replyView.tintColor = UIColor.messageBox.myReply()
        }else if self.isAdminMessage() {
            bubbleView.tintColor = UIColor.messageBox.admin()
            replyView.tintColor = UIColor.messageBox.adminReply()
        }else {
            bubbleView.tintColor = UIColor.messageBox.normal()
            replyView.tintColor = UIColor.messageBox.normalReply()
        }
    }
    //tag: stockviva end
}

//MARK: - adminMsgDisclaimerLabel control
extension ALKPhotoCell {
    func isHiddenAdminDisclaimer(_ isHidden:Bool ){
        self.adminMsgDisclaimerLabel.isHidden = isHidden
        if isHidden {
            self.adminMsgDisclaimerLabel.text = ""
        }else{
            self.adminMsgDisclaimerLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_group_message_disclaimer")
        }
        
        self.adminMsgDisclaimerLabelHeightConst?.constant = isHidden ? 0 : Padding.AdminMsgDisclaimerLabel.height
        self.adminMsgDisclaimerLabelBottomConst?.constant = isHidden ? 0 : -Padding.AdminMsgDisclaimerLabel.bottom
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
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKPhotoCell - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKPhotoCell - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            DispatchQueue.main.async {
                self.setThumbnail(filePath)
            }
            self.updateThumbnailPath(identifier, filePath: filePath)
            return
        }
        
        //check can open or not
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(filePath).path
        let originalPath = task.urlString ?? ""
        if UIImage(contentsOfFile: path) == nil {
            if UIImage(contentsOfFile: originalPath) != nil {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKPhotoCell - dataDownloadingFinished with wrong file format,but web url work, filePath:\(filePath ), msg_key:\(identifier), webPath:\(originalPath)")
            }else{
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKPhotoCell - dataDownloadingFinished with wrong file format, filePath:\(filePath ), msg_key:\(identifier), webPath:\(originalPath)")
            }
            try? FileManager.default.removeItem(atPath: path)
            //update view
            DispatchQueue.main.async {
                self.updateView(for: .download)
                self.delegate?.didDownloadImageFailure()
            }
            return
        }
        
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
