//
//  ALKFriendVoiceCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation

class ALKFriendVoiceCell: ALKVoiceCell {

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 22.5
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        return label
    }()

    override class func topPadding() -> CGFloat {
        return 28
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let heigh: CGFloat
        heigh = 52
        //10(top pedding) + 34(user name label) + height(voic content) + 23(timeLabel)
        return 10+34+heigh+23
    }

    override func setupStyle() {
        super.setupStyle()
        //nameLabel.setStyle(ALKMessageStyle.displayName)
        if(ALKMessageStyle.receivedBubble.style == .edge) {
            //bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
            //bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        } else {
            //bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            //bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            //bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
        }
        soundPlayerView.backgroundColor = ALKMessageStyle.receivedBubble.color
        soundPlayerView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
    }


    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel])

        let width = 245

        soundPlayerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 0).isActive = true
        soundPlayerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0).isActive = true
        soundPlayerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0).isActive = true
        soundPlayerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 7).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 7).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -15).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: soundPlayerView.topAnchor, constant: -7).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7).isActive = true
        avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -7).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true

        bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 7).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 13).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {

            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {

            self.avatarImageView.image = placeHolder
        }
        nameLabel.text = viewModel.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
        //set color
        if let _messageUserId = viewModel.contactId,
            let _nameLabelColor = ALKConfiguration.share.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            nameLabel.textColor = _nameLabelColor
        }
    }

    override class func bottomPadding() -> CGFloat {
        return 6
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
}
