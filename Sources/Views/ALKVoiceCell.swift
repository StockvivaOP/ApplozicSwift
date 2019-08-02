//
//  ALKVoiceCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

import UIKit
import Foundation
import Kingfisher
import AVFoundation
import Applozic

protocol ALKVoiceCellProtocol: class {
    func playAudioPress(identifier: String)
}

public enum ALKVoiceCellState {
    case playing
    case stop
    case pause
}

class ALKVoiceCell:ALKChatBaseCell<ALKMessageViewModel>,
                    ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol {

    var soundPlayerView: UIView = {
        let mv = UIView()
        mv.contentMode = .scaleAspectFill
        mv.clipsToBounds = true
        mv.layer.cornerRadius = 12
        mv.backgroundColor = UIColor.clear
        return mv
    }()

    fileprivate let frameView: ALKTappableView = {
        let view = ALKTappableView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    var playTimeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor102()
        return lb
    }()

    var progressBar: UISlider = {
        let view = UISlider()
        view.value = 0.0
        view.minimumValue = 0.0
        view.maximumValue = 1.0
        var _img = UIImage.createCircleImage(color: UIColor.ALKSVMainColorPurple(), frame: CGRect(x: 0, y: 0, width: 10, height: 10) )
        view.setThumbImage(_img, for: UIControl.State.normal)
        view.minimumTrackTintColor = UIColor.ALKSVMainColorPurple()
        view.maximumTrackTintColor = UIColor.ALKSVColorLightPurple()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor153()
        return lb
    }()

    var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.contentEdgeInsets = UIEdgeInsets(top: 17, left: 27, bottom: 17, right: 20)
        return button
    }()

    var clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()

    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    var downloadTapped:((Bool)->Void)?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 12
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let heigh: CGFloat
        heigh = 52
        return topPadding()+heigh+bottomPadding()
    }

    func getTimeString(secLeft:CGFloat) -> String {

        let min = (Int(secLeft) / 60) % 60
        let sec = (Int(secLeft) % 60)
        let minStr = String(min)
        var secStr = String(sec)
        if sec < 10 {secStr = "0\(secStr)"}

        return "\(minStr):\(secStr)"
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        /// Auto-Download
        if viewModel.filePath == nil {
            downloadTapped?(true)
        } else if let filePath = viewModel.filePath {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            if let data = NSData(contentsOfFile: (documentsURL.appendingPathComponent(filePath)).path) as Data? {
                updateViewForDownloadedState(data: data)
            }
        }

        let timeLeft = Int(viewModel.voiceTotalDuration)-Int(viewModel.voiceCurrentDuration)
        let totalTime = Int(viewModel.voiceTotalDuration)
        let percent = viewModel.voiceTotalDuration == 0 ? 0 : Float(timeLeft)/Float(totalTime)

        let currentPlayTime = CGFloat(timeLeft)

        if viewModel.voiceCurrentState == .pause && viewModel.voiceCurrentDuration > 0 {
            actionButton.isSelected = false
            playTimeLabel.text = getTimeString(secLeft: viewModel.voiceTotalDuration)
        } else if viewModel.voiceCurrentState == .playing {
            print("identifier: ", viewModel.identifier)
            actionButton.isSelected = true
            playTimeLabel.text = getTimeString(secLeft:currentPlayTime)
        } else if viewModel.voiceCurrentState == .stop {
            actionButton.isSelected = false
            playTimeLabel.text = getTimeString(secLeft:currentPlayTime)
        } else {
            actionButton.isSelected = false
            playTimeLabel.text = getTimeString(secLeft:currentPlayTime)
        }

        if viewModel.voiceCurrentState == .stop || viewModel.voiceCurrentDuration == 0 {
            progressBar.setValue(0, animated: false)
        } else {
            progressBar.setValue(Float(percent), animated: false)
        }
        timeLabel.text   = viewModel.time
    }

    weak var voiceDelegate: ALKVoiceCellProtocol?

    func setCellDelegate(delegate:ALKVoiceCellProtocol) {
        voiceDelegate = delegate
    }

    @objc func actionTapped() {
        guard let identifier = viewModel?.identifier else {return}
        voiceDelegate?.playAudioPress(identifier: identifier)
    }

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
        //playTimeLabel.setStyle(ALKMessageStyle.playTime)
    }

    override func setupViews() {
        super.setupViews()

        self.accessibilityIdentifier = "audioCell"

        actionButton.setImage(UIImage(named: "icon_play", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        actionButton.setImage(UIImage(named: "icon_pause", in: Bundle.applozic, compatibleWith: nil), for: .selected)
        actionButton.tintColor = UIColor.ALKSVMainColorPurple()

        frameView.addGestureRecognizer(longPressGesture)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(ALKVoiceCell.soundPlayerAction), for: .touchUpInside)

        contentView.addViewsForAutolayout(views: [soundPlayerView,bubbleView,progressBar,actionButton,playTimeLabel,frameView,timeLabel,clearButton])
        contentView.bringSubviewToFront(soundPlayerView)
        contentView.bringSubviewToFront(progressBar)
        contentView.bringSubviewToFront(playTimeLabel)
        contentView.bringSubviewToFront(clearButton)
        contentView.bringSubviewToFront(frameView)
        contentView.bringSubviewToFront(actionButton)

        progressBar.centerYAnchor.constraint(equalTo: soundPlayerView.centerYAnchor).isActive = true
        progressBar.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor).isActive = true
        progressBar.trailingAnchor.constraint(equalTo: soundPlayerView.trailingAnchor,constant:-18).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: 10).isActive = true

        frameView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0).isActive = true
        frameView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0).isActive = true
        frameView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
        frameView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0).isActive = true

        clearButton.topAnchor.constraint(equalTo: soundPlayerView.topAnchor).isActive = true
        clearButton.bottomAnchor.constraint(equalTo: soundPlayerView.bottomAnchor).isActive = true
        clearButton.leftAnchor.constraint(equalTo: soundPlayerView.leftAnchor).isActive = true
        clearButton.rightAnchor.constraint(equalTo: soundPlayerView.rightAnchor).isActive = true

        playTimeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 2).isActive = true
        playTimeLabel.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor).isActive = true
        playTimeLabel.bottomAnchor.constraint(equalTo: soundPlayerView.bottomAnchor,constant:-4).isActive = true
        playTimeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: progressBar.trailingAnchor,constant:0).isActive = true
        playTimeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        actionButton.topAnchor.constraint(equalTo: soundPlayerView.topAnchor).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        actionButton.leadingAnchor.constraint(equalTo: soundPlayerView.leadingAnchor).isActive = true
        actionButton.widthAnchor.constraint(equalToConstant: 61).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    deinit {
        clearButton.removeTarget(self, action: #selector(ALKVoiceCell.soundPlayerAction), for: .touchUpInside)
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    func updateViewForDownloadedState(data: Data) {
        do {
            let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
            viewModel?.voiceData = data
            viewModel?.voiceTotalDuration = CGFloat(player.duration)
            playTimeLabel.text = getTimeString(secLeft:viewModel!.voiceTotalDuration)
        } catch(let error) {
            print(error)
        }
    }

    @objc private func soundPlayerAction() {
        guard isMessageSent() else { return }
        showMediaViewer()
    }

    private func isMessageSent() -> Bool {
        guard let viewModel = viewModel else { return false}
        return viewModel.isSent || viewModel.isAllReceived || viewModel.isAllRead
    }

    private func showMediaViewer() {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mediaViewer, bundle: Bundle.applozic)

        let nav = storyboard.instantiateInitialViewController() as? UINavigationController
        let vc = nav?.viewControllers.first as? ALKMediaViewerViewController
        let dbService = ALMessageDBService()
        guard let messages = dbService.getAllMessagesWithAttachment(
            forContact: viewModel?.contactId,
            andChannelKey: viewModel?.channelKey,
            onlyDownloadedAttachments: true) as? [ALMessage] else { return }

        let messageModels = messages.map { $0.messageModel }
        NSLog("Messages with attachment: ", messages )

        guard let viewModel = viewModel as? ALKMessageModel,
            let currentIndex = messageModels.index(of: viewModel) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex, localizedStringFileName: localizedStringFileName)
        UIViewController.topViewController()?.present(nav!, animated: true, completion: {
        })
    }

    fileprivate func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        let dbMessage: DB_Message = messageService.getMessageByKey(key, value: value) as! DB_Message
        dbMessage.filePath = filePath
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }

    func menuReply(_ sender: Any) {
        menuAction?(.reply)
    }
    
    func menuAppeal(_ sender: Any) {
        if let _chatGroupID = self.clientChannelKey,
            let _userID = self.viewModel?.contactId,
            let _msgID = self.viewModel?.identifier {
            self.delegateConversationMessageBoxAction?.didMenuAppealClicked(chatGroupHashID:_chatGroupID, userHashID:_userID, messageID:_msgID)
        }
    }
}

extension ALKVoiceCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {

    }

    func dataDownloadingFinished(task: ALKDownloadTask) {

        // update viewmodel's data field and time and then call update
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, let _ = self.viewModel else {
            return
        }
        self.updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let data = NSData(contentsOfFile: (documentsURL.appendingPathComponent(task.filePath ?? "")).path) as Data? {
            updateViewForDownloadedState(data: data)
        }
    }
}
