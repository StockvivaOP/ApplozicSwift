//
//  ALKVideoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Applozic
import AVKit

class ALKVideoCell: ALKChatBaseCell<ALKMessageViewModel>,
                    ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol, ALKDeleteMsgMenuItemProtocol {

    var delegate: AttachmentDelegate?

    var photoView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
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

    fileprivate var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.isHidden = true
        return button
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    fileprivate var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PLAY", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.clockwise = true
        return view
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    var url: URL?

    var uploadTapped:((Bool) ->Void)?
    var uploadCompleted: ((_ responseDict: Any?) ->Void)?

    var downloadTapped:((Bool) ->Void)?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let heigh: CGFloat

        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }

        return topPadding()+heigh+bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.date.toConversationViewDateFormat() //viewModel.time
        guard let state = viewModel.attachmentState() else { return }
        updateView(for: state)
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
    
    @objc func actionTapped(button: UIButton) {
        button.isEnabled = false
    }

    override func setupStyle() {
        super.setupStyle()

        timeLabel.setStyle(ALKMessageStyle.time)
        fileSizeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        playButton.isHidden = true
        progressView.isHidden = true
        uploadButton.isHidden = true

        frontView.addGestureRecognizer(longPressGesture)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(ALKVideoCell.downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)
        uploadButton.addTarget(self, action: #selector(ALKVideoCell.uploadButtonAction(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(ALKVideoCell.playButtonAction(_:)), for: .touchUpInside)

        contentView.addViewsForAutolayout(views: [frontView, photoView,bubbleView, timeLabel,fileSizeLabel, downloadButton, playButton, progressView, uploadButton])
        contentView.bringSubviewToFront(photoView)
        contentView.bringSubviewToFront(frontView)
        contentView.bringSubviewToFront(actionButton)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(playButton)
        contentView.bringSubviewToFront(progressView)
        contentView.bringSubviewToFront(uploadButton)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        playButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        progressView.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
    }

    deinit {
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
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
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    func menuReply(_ sender: Any) {
        menuAction?(.reply)
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - message menu click reply:\(self.viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
    }
    
    func menuAppeal(_ sender: Any) {
        menuAction?(.appeal(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), messageID: self.viewModel?.identifier, message: self.viewModel?.message))
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - message menu click appeal:\(self.viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
    }

    func menuPinMsg(_ sender: Any) {
        menuAction?(.pinMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - message menu click pin msg:\(self.viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
    }
    
    func menuDeleteMsg(_ sender: Any){
        menuAction?(.deleteMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.getMessageSenderHashId(), viewModel: self.viewModel, indexPath:self.indexPath))
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - message menu click delete msg:\(self.viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
    }
    
    @objc private func downloadButtonAction(_ selector: UIButton) {
        downloadTapped?(true)
    }

    @objc private func playButtonAction(_ selector: UIButton) {
        guard let viewModel = self.viewModel else { return }
        delegate?.tapAction(message: viewModel)
    }

    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateView(for state: AttachmentState) {
        switch state {
        case .download:
            uploadButton.isHidden = true
            downloadButton.isHidden = false
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            playButton.isHidden = true
            progressView.isHidden = true
        case .downloaded(let filePath):
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = true
            viewModel?.filePath = filePath
            playButton.isHidden = false
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            photoView.image = getThumbnail(filePath: path)
        case .downloading(let progress, _):
            // show progress bar
            print("downloading")
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = false
            progressView.angle = progress
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
        case .upload:
            downloadButton.isHidden = true
            progressView.isHidden = true
            playButton.isHidden = true
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            uploadButton.isHidden = false
        default:
            print("Not handled")
        }
    }

    private func getThumbnail(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            return UIImage(cgImage: cgImage)

        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    fileprivate func convertToDegree(total: Int64, written: Int64) -> Double {
        let divergence = Double(total)/360.0
        let degree = Double(written)/divergence
        return degree
    }
}

extension ALKVideoCell: ALKHTTPManagerUploadDelegate {
    func dataUploaded(task: ALKUploadTask) {
        NSLog("Data uploaded: \(task.totalBytesUploaded) out of total: \(task.totalBytesExpectedToUpload)")
        let progress = self.convertToDegree(total: task.totalBytesExpectedToUpload, written: task.totalBytesUploaded)
        self.updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        NSLog("VIDEO CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
        if task.uploadError == nil && task.completed == true && task.filePath != nil {
            DispatchQueue.main.async {
                self.updateView(for: .downloaded(filePath: task.filePath ?? ""))
            }
        } else {
            DispatchQueue.main.async {
                self.updateView(for: .upload)
            }
        }
    }
}

extension ALKVideoCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        NSLog("VIDEO CELL DATA UPDATED AND FILEPATH IS: %@", viewModel?.filePath ?? "")
        let total = task.totalBytesExpectedToDownload
        let progress = self.convertToDegree(total: total, written: task.totalBytesDownloaded)
        self.updateView(for: .downloading(progress: progress, totalCount: total))
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
            updateView(for: .download)
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
