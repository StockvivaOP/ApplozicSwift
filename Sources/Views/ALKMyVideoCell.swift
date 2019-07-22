//
//  ALKMyVideoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

class ALKMyVideoCell: ALKVideoCell {

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    override func setupViews() {
        super.setupViews()

        let width = UIScreen.main.bounds.width

        contentView.addViewsForAutolayout(views: [stateView])
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 48).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: width*0.60).isActive = true
        
        photoView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        photoView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        photoView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        photoView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        
        fileSizeLabel.rightAnchor.constraint(equalTo: photoView.rightAnchor, constant: -12).isActive = true
        
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        stateView.widthAnchor.constraint(equalToConstant: 17).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -6).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        if viewModel.isAllRead {
            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor(netHex: 0x0578FF)
        } else if viewModel.isAllReceived {
            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVGreyColor153()
        } else if viewModel.isSent {
            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVGreyColor153()
        } else {
            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVMainColorPurple()
        }
    }

    override class func bottomPadding() -> CGFloat {
        return 6
    }

    override func setupStyle() {
        super.setupStyle()
        if(ALKMessageStyle.sentBubble.style == .edge) {
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
        } else {
//            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        }
        photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        bubbleView.image = nil
    }
    
    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let heigh: CGFloat
        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }
        //10(top padding) + heigh + 25(statusLabel)
        return 10+heigh+25
    }
}
