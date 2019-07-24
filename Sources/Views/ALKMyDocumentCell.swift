//
//  ALKMyDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import Foundation
import Applozic
import UIKit
import Kingfisher

class ALKMyDocumentCell: ALKDocumentCell {

    struct Padding {
        struct  StateView {
            static let right: CGFloat = 8
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let height: CGFloat = 15
            static let width: CGFloat = 17
        }
        
        struct  TimeLabel {
            static let top: CGFloat = 0
            static let right: CGFloat = 6
            static let height: CGFloat = 15
        }
        struct  BubbleView {
            static let top: CGFloat = 10
            static let right: CGFloat = 7
            static let width: CGFloat = 254
        }
    }

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()
    
    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [timeLabel, stateView])
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.StateView.top).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.StateView.right).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.StateView.bottom).isActive = true
        stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height).isActive = true

        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: Padding.TimeLabel.top).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -Padding.TimeLabel.right).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true

        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.right).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant:Padding.BubbleView.width).isActive = true
        
        frameUIView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frameUIView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        frameUIView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        frameUIView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
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

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
        bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.BubbleView.top + Padding.StateView.top + Padding.StateView.height + Padding.StateView.bottom
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 0
        var messageHeight : CGFloat = 0.0
        messageHeight += heightPadding()
        return max(messageHeight, minimumHeight)
    }

}
