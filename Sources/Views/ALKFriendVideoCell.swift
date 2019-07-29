//
//  ALKFriendVideoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Kingfisher

class ALKFriendVideoCell: ALKVideoCell {

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

    override func setupStyle() {
        super.setupStyle()
        nameLabel.setStyle(ALKMessageStyle.displayName)
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
        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -11).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7).isActive = true
        avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -7).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true

        bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56).isActive = true
        
        photoView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 7).isActive = true
        photoView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        photoView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        photoView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true

        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 7).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 13).isActive = true

        fileSizeLabel.leftAnchor.constraint(equalTo: photoView.leftAnchor, constant: 12).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        nameLabel.text = viewModel.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
        //set color
        if let _messageUserId = viewModel.contactId,
            let _nameLabelColor = ALKConfiguration.share.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            nameLabel.textColor = _nameLabelColor
        }

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        guard let url = viewModel.avatarURL else {
            self.avatarImageView.image = placeHolder
            return
        }
        let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
        self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)

    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let heigh: CGFloat
        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }
        //10(top padding) + 34(user name label) + height(video content) + 23(timeLabel)
        return 10+34+heigh+23
    }
    
    
    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
}
