//
//  ALKFriendDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import Foundation
import Applozic
import UIKit
import Kingfisher
import Applozic

class ALKFriendDocumentCell: ALKDocumentCell {

    struct Padding {

        struct NameLabel {
            static let top: CGFloat = 7.0
            static let left: CGFloat = 7.0
            static let right: CGFloat = 11.0
            static let height: CGFloat = 20.0
        }
        
        struct AvatarImage {
            static let top: CGFloat = 10.0
            static let left: CGFloat = 7.0
            static let width: CGFloat = 45.0
            static let height: CGFloat = 45.0
        }
        
        struct TimeLabel {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let left: CGFloat = 7
            static let height: CGFloat = 13
        }
        
        struct BubbleView {
            static let left: CGFloat = 7.0
            static let width: CGFloat = 254
        }

        struct FrameUIView {
            static let top: CGFloat = 7.0
        }
    }

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 22.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel,timeLabel])
        
        nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: Padding.NameLabel.top).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.NameLabel.left).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.NameLabel.right).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height).isActive = true
        
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.AvatarImage.top).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.AvatarImage.left).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width).isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.TimeLabel.left).isActive = true
        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.TimeLabel.top).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.TimeLabel.bottom).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.BubbleView.left).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant:Padding.BubbleView.width).isActive = true
        
        frameUIView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.FrameUIView.top).isActive = true
        frameUIView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        frameUIView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        frameUIView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
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

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
        //nameLabel.setStyle(ALKMessageStyle.displayName)
        bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 60 // 55 is avatar image... + padding
        let messageHeight : CGFloat = self.heightPadding()
        return max(messageHeight, minimumHeight)
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.AvatarImage.top + Padding.NameLabel.top + Padding.NameLabel.height + Padding.FrameUIView.top + Padding.TimeLabel.top + Padding.TimeLabel.height + Padding.TimeLabel.bottom
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }

}
