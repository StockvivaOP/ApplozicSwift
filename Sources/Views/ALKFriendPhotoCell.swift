//
//  FriendPhotoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Kingfisher

// MARK: - FriendPhotoCell
class ALKFriendPhotoCell: ALKPhotoCell {

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

    struct Padding {
        struct PhotoView {
            static let right: CGFloat = 0
        }
    }

    override class func topPadding() -> CGFloat {
        return 28
    }

    override class var messageTextFont: UIFont {
        return ALKMessageStyle.receivedMessage.font
    }

    override func setupStyle() {
        super.setupStyle()
        //nameLabel.setStyle(ALKMessageStyle.displayName)
        //captionLabel.font = ALKMessageStyle.receivedMessage.font
        //captionLabel.textColor = ALKMessageStyle.receivedMessage.text
        if(ALKMessageStyle.receivedBubble.style == .edge) {
            //bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            //bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
            photoView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        } else {
            photoView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            //bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        }
        bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
    }

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel])
        nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 7).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 7).isActive = true

        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -15).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        //avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true

        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7).isActive = true
        avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -7).isActive = true

        avatarImageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 45).isActive = true

        bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        bubbleView.widthAnchor
            .constraint(equalToConstant: ALKPhotoCell.maxWidth*ALKPhotoCell.widthPercentage)
            .isActive = true
        bubbleView.heightAnchor
            .constraint(equalToConstant: (ALKPhotoCell.maxWidth*ALKPhotoCell.heightPercentage) + 7)
            .isActive = true
        
        photoView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 7).isActive = true
        photoView.leadingAnchor
            .constraint(lessThanOrEqualTo: bubbleView.leadingAnchor, constant: 0)
            .isActive = true
        photoView.trailingAnchor
            .constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: 0)
            .isActive = true

        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 7).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 13).isActive = true

        fileSizeLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        nameLabel.text = viewModel.displayName

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {

            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {

            self.avatarImageView.image = placeHolder
        }
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
        
        //34(user name label) + height(photo content) + 34(captionLabel) + 23(timeLabel)
        return 34+height+34+23
    }
    
    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
    
    // MARK: - ChatMenuCell
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        self.bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.receivedBubble.style,isReceiverSide: true,showHangOverImage: true)
    }
    
    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        self.bubbleView.image =  setBubbleViewImage(for: ALKMessageStyle.receivedBubble.style,isReceiverSide: true,showHangOverImage: false)
    }
}
