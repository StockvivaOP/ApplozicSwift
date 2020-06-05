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
ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol, ALKDeleteMsgMenuItemProtocol, ALKBookmarkMsgMenuItemProtocol {

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
            static let left: CGFloat = 20
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
            static let bottom: CGFloat = 7.5
            static let left: CGFloat = 7.0
            static let right: CGFloat = 7.0
        }
        
        struct AdminMsgDisclaimerLabel {
            static let top: CGFloat = 7.5
            static let bottom: CGFloat = 7.5
            static let left: CGFloat = 7.0
            static let right: CGFloat = 7.0
            static let height: CGFloat = 11.0
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
        //uiView.image = UIImage.init(named: "temp_chat_attachment_bg_right", in: Bundle.applozic, compatibleWith: nil)
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
    
    var adminMsgDisclaimerLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 8)
        lb.textAlignment = .left
        lb.textColor = UIColor.ALKSVGreyColor102()
        return lb
    }()
    
    lazy var adminMsgDisclaimerLabelHeightConst:NSLayoutConstraint? = self.adminMsgDisclaimerLabel.heightAnchor.constraint(equalToConstant: 0)
    var adminMsgDisclaimerLabelBottomConst:NSLayoutConstraint?
    
    var replyViewAction: (()->())? = nil
    
    var replyMessageTypeImagewidthConst:NSLayoutConstraint?
    var replyMessageLabelConst:NSLayoutConstraint?
    //tag: stockviva end
    
    //MARK: stockviva tag start
    var fileNameTrailing :NSLayoutConstraint?
    var documentUpdateDelegate:ALKDocumentViewerControllerDelegate?
    
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

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.previewImageView.image = nil
        self.previewImageView.kf.cancelDownloadTask()
    }
    
    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [
        bubbleView,
        frameUIView,
        replyView,
        replyIndicatorView,
        replyNameLabel,
        replyMessageTypeImageView,
        replyMessageLabel,
        previewImageView,
        attachBgView,
        downloadButton,
        uploadButton,
        fileNameLabel,
        docImageView,
        sizeAndFileType,
        frontView,
        adminMsgDisclaimerLabel,
        progressView])
        
        contentView.bringSubviewToFront(uploadButton)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(progressView)
        contentView.bringSubviewToFront(replyView)
        contentView.bringSubviewToFront(replyIndicatorView)
        contentView.bringSubviewToFront(replyNameLabel)
        contentView.bringSubviewToFront(replyMessageTypeImageView)
        contentView.bringSubviewToFront(replyMessageLabel)
        contentView.bringSubviewToFront(previewImageView)
        contentView.bringSubviewToFront(adminMsgDisclaimerLabel)
        frontView.addGestureRecognizer(longPressGesture)

        let topToOpen = UITapGestureRecognizer(target: self, action: #selector(self.openWKWebView(gesture:)))
        
        //tag: stockviva start
        let replyTapGesture = UITapGestureRecognizer(target: self, action: #selector(replyViewTapped))
        replyView.addGestureRecognizer(replyTapGesture)
        //tag: stockviva end
        
        frontView.isUserInteractionEnabled = true
        frontView.addGestureRecognizer(topToOpen)

        downloadButton.addTarget(self, action: #selector(self.downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)
        uploadButton.addTarget(self, action: #selector(self.uploadButtonAction(_:)), for: UIControl.Event.touchUpInside)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        attachBgView.topAnchor.constraint(equalTo: frameUIView.topAnchor, constant: CommonPadding.AttachBgUIView.top).isActive = true
        attachBgView.bottomAnchor.constraint(equalTo: adminMsgDisclaimerLabel.topAnchor, constant: -CommonPadding.AttachBgUIView.bottom).isActive = true
        attachBgView.leftAnchor.constraint(equalTo: frameUIView.leftAnchor, constant: CommonPadding.AttachBgUIView.left).isActive = true
        attachBgView.rightAnchor.constraint(equalTo: frameUIView.rightAnchor, constant: -CommonPadding.AttachBgUIView.right).isActive = true
        
        self.adminMsgDisclaimerLabelHeightConst?.isActive = true
        self.adminMsgDisclaimerLabelBottomConst = adminMsgDisclaimerLabel.bottomAnchor.constraint(equalTo: frameUIView.bottomAnchor, constant: -CommonPadding.AdminMsgDisclaimerLabel.bottom)
        self.adminMsgDisclaimerLabelBottomConst?.isActive = true
        self.adminMsgDisclaimerLabel.leadingAnchor.constraint(
                equalTo: frameUIView.leadingAnchor,
                constant: CommonPadding.AdminMsgDisclaimerLabel.left).isActive = true
        self.adminMsgDisclaimerLabel.trailingAnchor.constraint(
                equalTo:frameUIView.trailingAnchor,
                constant: -CommonPadding.AdminMsgDisclaimerLabel.right).isActive = true
        
        docImageView.centerYAnchor.constraint(equalTo: attachBgView.centerYAnchor).isActive = true
        docImageView.leadingAnchor.constraint(equalTo: attachBgView.leadingAnchor, constant: CommonPadding.DocumentView.left).isActive = true
        docImageView.widthAnchor.constraint(equalToConstant: CommonPadding.DocumentView.width).isActive = true
        docImageView.heightAnchor.constraint(equalToConstant: CommonPadding.DocumentView.height).isActive = true

        fileNameLabel.centerYAnchor.constraint(equalTo: attachBgView.centerYAnchor).isActive = true
        fileNameLabel.heightAnchor.constraint(equalToConstant: CommonPadding.FileNameLabel.height).isActive = true
        self.fileNameTrailing = fileNameLabel.trailingAnchor.constraint(equalTo: attachBgView.trailingAnchor, constant: -CommonPadding.FileNameLabel.right)
        self.fileNameTrailing?.isActive = true

        downloadButton.topAnchor.constraint(equalTo: attachBgView.topAnchor, constant: CommonPadding.DownloadButton.top).isActive = true
        downloadButton.leadingAnchor.constraint(equalTo: attachBgView.leadingAnchor, constant: CommonPadding.DownloadButton.left).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.width).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.height).isActive = true

        sizeAndFileType.topAnchor.constraint(equalTo: downloadButton.bottomAnchor).isActive = true
        sizeAndFileType.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor).isActive = true
        sizeAndFileType.trailingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor, constant: -CommonPadding.FileTypeView.right).isActive = true
        sizeAndFileType.bottomAnchor.constraint(equalTo: attachBgView.bottomAnchor, constant: -CommonPadding.FileTypeView.bottom).isActive = true
        sizeAndFileType.heightAnchor.constraint(equalToConstant: CommonPadding.FileTypeView.height).isActive = true
        sizeAndFileType.widthAnchor.constraint(greaterThanOrEqualToConstant: CommonPadding.FileTypeView.width).isActive = true

        uploadButton.topAnchor.constraint(equalTo: downloadButton.topAnchor).isActive = true
        uploadButton.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalTo: downloadButton.widthAnchor).isActive = true
        uploadButton.widthAnchor.constraint(equalTo: downloadButton.heightAnchor).isActive = true
        
        progressView.topAnchor.constraint(equalTo: downloadButton.topAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor).isActive = true
        progressView.heightAnchor.constraint(equalTo: downloadButton.widthAnchor).isActive = true
        progressView.widthAnchor.constraint(equalTo: downloadButton.heightAnchor).isActive = true

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

    class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat, replyMessage: ALKMessageViewModel?) -> CGFloat {
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
        docViewController.message = self.viewModel
        docViewController.delegate = self.documentUpdateDelegate
        let pushAssist = ALPushAssist()
        pushAssist.topViewController.navigationController?.pushViewController(docViewController, animated: false)
    }

    class func commonHeightPadding() -> CGFloat {
        return CommonPadding.AttachBgUIView.top + CommonPadding.AttachBgUIView.bottom + CommonPadding.DownloadButton.top + CommonPadding.DownloadButton.height + CommonPadding.FileTypeView.height + CommonPadding.FileTypeView.bottom
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.date.toConversationViewDateFormat() //viewModel.time
        
        if self.viewModel?.isInvalidAttachement() == true {
            fileNameLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_not_support") ?? ""
            sizeAndFileType.text = ""
            self.updateViewForInvlidAttachmentState()
            return
        }

        fileNameLabel.text = ALKFileUtils().getFileName(filePath: viewModel.filePath, fileMeta: viewModel.fileMetaInfo)

        let size = ALKFileUtils().getFileSize(filePath: viewModel.filePath, fileMetaInfo: viewModel.fileMetaInfo) ?? ""

        let fileType =  ALKFileUtils().getFileExtenion(filePath: viewModel.filePath,fileMeta: viewModel.fileMetaInfo)

        if(!size.isEmpty) {
            sizeAndFileType.text =  size + " \u{2022} " + fileType
        }

        guard let state = viewModel.attachmentState() else { return }
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
    
    //for invlid attachment
    func updateViewForInvlidAttachmentState(){
        docImageView.image = UIImage(named: "icon_send_file", in: Bundle.applozic, compatibleWith: nil)
        attachBgView.isHidden = true
        docImageView.isHidden = false
        downloadButton.isHidden = true
        uploadButton.isHidden = true
        progressView.isHidden = true
        sizeAndFileType.isHidden = true
        self.uploadTapped = nil
        self.uploadCompleted = nil
        self.downloadTapped = nil
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch self {
        case let menuItem as ALKPinMsgMenuItemProtocol where action == menuItem.selector:
            if self.viewModel?.isInvalidAttachement() == true || self.viewModel?.getSVMessageStatus() != .sent {
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
            attachBgView.tintColor = UIColor.messageBox.myInner()
        }else if self.isAdminMessage() {
            bubbleView.tintColor = UIColor.messageBox.admin()
            replyView.tintColor = UIColor.messageBox.adminReply()
            attachBgView.tintColor = UIColor.messageBox.adminInner()
        }else {
            bubbleView.tintColor = UIColor.messageBox.normal()
            replyView.tintColor = UIColor.messageBox.normalReply()
            attachBgView.tintColor = UIColor.messageBox.normalInner()
        }
        
        if isReceiverSide {
            attachBgView.image = UIImage.init(named: "temp_chat_attachment_bg_left", in: Bundle.applozic, compatibleWith: nil)
        }else{
            attachBgView.image = UIImage.init(named: "temp_chat_attachment_bg_right", in: Bundle.applozic, compatibleWith: nil)
        }
    }
    //tag: stockviva end
}

//MARK: - adminMsgDisclaimerLabel control
extension ALKDocumentCell {
    func isHiddenAdminDisclaimer(_ isHidden:Bool ){
        self.adminMsgDisclaimerLabel.isHidden = isHidden
        if isHidden {
            self.adminMsgDisclaimerLabel.text = ""
        }else{
            self.adminMsgDisclaimerLabel.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_group_message_disclaimer")
        }
        
        self.adminMsgDisclaimerLabelHeightConst?.constant = isHidden ? 0 : CommonPadding.AdminMsgDisclaimerLabel.height
        self.adminMsgDisclaimerLabelBottomConst?.constant = isHidden ? 0 : -CommonPadding.AdminMsgDisclaimerLabel.bottom
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
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKDocumentCell - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            DispatchQueue.main.async {
                self.updateView(for: .download)
            }
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKDocumentCell - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
