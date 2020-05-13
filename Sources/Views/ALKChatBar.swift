//
//  ALKChatBar.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit
import Applozic

public struct AutoCompleteItem {
    var key: String
    var content: String

    public init(key: String, content: String) {
        self.key = key
        self.content = content
    }
}

// swiftlint:disable:next type_body_length
open class ALKChatBar: UIView, Localizable {

    var configuration: ALKConfiguration!
    
    var delegate:ChatBarRequestActionDelegate?

    public var chatBarConfiguration: ALKChatBarConfiguration {
        return configuration.chatBar
    }
    public var isMicButtonHidden: Bool!

    public enum ButtonMode {
        case send
        case media
    }

    public enum ActionType {
        case sendText(UIButton,String,[(hashID:String, name:String)]?)
        case chatBarTextBeginEdit
        case chatBarTextChange(UIButton)
        case sendVoice(NSData)
        case startVideoRecord
        case startVoiceRecord
        case showUploadAttachmentFile
        case showImagePicker
        case showLocation
        case noVoiceRecordPermission
        case mic(UIButton)
        case more(UIButton)
        case cameraButtonClicked(UIButton)
        case shareContact
    }

    public var action: ((ActionType) -> Void)?

    public var autocompletionView: UITableView!

    lazy open var soundRec: ALKAudioRecorderView = {
        let view = ALKAudioRecorderView(frame: CGRect.zero, configuration: self.configuration)
        view.layer.masksToBounds = true
        return view
    }()

    /// A header view which will be present on top of the chat bar.
    /// Use this to add custom views on top. It's default height will be 0.
    /// Make sure to set the height using `headerViewHeight` property.
    open var headerView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.clear
        view.accessibilityIdentifier = "Header view"
        return view
    }()

    /// Use this to set `headerView`'s height. Default height is 0.
    open var headerViewHeight: Double = 0 {
        didSet {
            headerView.constraint(withIdentifier: ConstraintIdentifier.headerViewHeight.rawValue)?.constant = CGFloat(headerViewHeight)
        }
    }

    public let textView: ALKChatBarTextView = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        let tv = ALKChatBarTextView()
        tv.setBackgroundColor(UIColor.ALKSVGreyColor245())
        tv.scrollsToTop = false
        tv.autocapitalizationType = .sentences
        tv.accessibilityIdentifier = "chatTextView"
        tv.typingAttributes = [NSAttributedString.Key.paragraphStyle: style, NSAttributedString.Key.font: UIFont.font(.normal(size: 16.0))]
        tv.layer.cornerRadius = 37.0 / 2.0
        tv.layer.borderColor = UIColor.ALKSVGreyColor207().cgColor
        tv.textContainerInset.top = 10.0
        tv.textContainerInset.left = 15.0
        tv.textContainerInset.right = 15.0
        tv.layer.borderWidth = 1
        return tv
    }()

    open var frameView: UIImageView = {

        let view = UIImageView()
        view.backgroundColor = .clear
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = false
        return view
    }()

    open var grayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ALKSVGreyColor250()
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy open var placeHolder: UITextView = {
        let view = UITextView()
        view.setFont(UIFont.font(.normal(size: 16)))
        view.setTextColor(UIColor.ALKSVGreyColor153())
        view.text = ""
        view.isUserInteractionEnabled = false
        view.isScrollEnabled = false
        view.scrollsToTop = false
        view.setBackgroundColor(.color(.none))
        view.contentInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        return view
    }()

    open var micButton: AudioRecordButton = {
        let button = AudioRecordButton(frame: CGRect())
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = "MicButton"
        return button
    }()

    open var photoButton: UIButton = {
        let bt = UIButton(type: .custom)
        return bt
    }()

    open var galleryButton: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()

    open var plusButton: UIButton = {

        let bt = UIButton(type: .custom)
        var image = UIImage(named: "icon_more_menu", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        bt.setImage(image, for: .normal)
        return bt
    }()

    open var locationButton: UIButton = {

        let bt = UIButton(type: .custom)
        return bt
    }()

    open var contactButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.widthAnchor.constraint(equalToConstant: 20)
        return button
    }()

    open var lineImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "line", in: Bundle.applozic, compatibleWith: nil))
        return imageView
    }()

    lazy open var sendButton: UIButton = {
        let bt = UIButton(type: .custom)
        var image = configuration.sendMessageIcon
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        bt.setImage(image, for: .normal)
        bt.accessibilityIdentifier = "sendButton"

        return bt
    }()

    open var lineView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.backgroundColor = UIColor.ALKSVGreyColor207()
        view.isHidden = true
        return view
    }()
    
    open var lineBottomView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.backgroundColor = UIColor.ALKSVGreyColor207()
        return view
    }()

    open var bottomGrayView: UIView = {
        let view = UIView()
        view.setBackgroundColor(UIColor.ALKSVGreyColor245())
        view.isUserInteractionEnabled = false
        return view
    }()

    open var videoButton: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    open var attachmentButton: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    open var joinGroupView: UIView = {
        let view = UIView()
        view.setBackgroundColor(UIColor.white)
        view.clipsToBounds = true
        return view
    }()
    
    open var joinGroupButton: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.ALKSVStockColorRed()
        view.setTitleColor(UIColor.white, for: .normal)
        view.setFont(font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        view.titleLabel?.textAlignment = .center
        view.semanticContentAttribute = .forceRightToLeft
        view.layer.cornerRadius = 18.5
        view.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        return view
    }()
    
    open var blockChatButton: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.clear
        view.setTitle("", for: .normal)
        return view
    }()
    
    open var mentionUserItems:[(hashID:String, name:String)] = []
    open var mentionUserList:UICollectionView = {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout:ALKChatBarMentionUserCollectionViewFlowLayout())
        view.showsHorizontalScrollIndicator = true
        view.showsVerticalScrollIndicator = false
        view.isHidden = true
        view.backgroundColor = .clear
        //register cell
        let _cell = UINib(nibName: "ALKChatBarTagUserListCollectionViewCell", bundle: Bundle.applozic)
        view.register(_cell, forCellWithReuseIdentifier: "ALKChatBarTagUserListCollectionViewCell")
        return view
    }()
    
    public var searchStockCodeTimer:Timer?
    public var lastSearchStockCodeInfo:(text:String, range:NSRange)?
    open var tagStockCodeItems:[(code:String, name:String)] = []
    open var tagStockCodeList:UICollectionView = {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout:ALKChatBarTagStockCodeCollectionViewFlowLayout())
        view.showsHorizontalScrollIndicator = true
        view.showsVerticalScrollIndicator = false
        view.isHidden = true
        view.backgroundColor = UIColor.ALKSVGreyColor207()
        //register cell
        let _cell = UINib(nibName: "ALKChatBarTagStockCodeListCollectionViewCell", bundle: Bundle.applozic)
        view.register(_cell, forCellWithReuseIdentifier: "ALKChatBarTagStockCodeListCollectionViewCell")
        return view
    }()
    
    /// Returns true if the textView is first responder.
    open var isTextViewFirstResponder: Bool {
        return textView.isFirstResponder
    }

    var isMediaViewHidden = false {
        didSet {
            if isMediaViewHidden {
                self.backgroundColor = UIColor.white
                bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 0
                attachmentButtonStackView.constraint(withIdentifier: ConstraintIdentifier.mediaStackViewHeight.rawValue)?.constant = 0

            } else {
                self.backgroundColor = self.bottomGrayView.backgroundColor
                bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 45
                attachmentButtonStackView.constraint(withIdentifier: ConstraintIdentifier.mediaStackViewHeight.rawValue)?.constant = 45
            }
        }
    }

    private var attachmentButtonStackView: UIStackView = {
        let attachmentStack = UIStackView(frame: CGRect.zero)
        return attachmentStack
    }()

    private enum ConstraintIdentifier: String {
        case mediaBackgroudViewHeight = "mediaBackgroudViewHeight"
        case poweredByMessageHeight = "poweredByMessageHeight"
        case headerViewHeight = "headerViewHeight"
        case mediaStackViewHeight = "mediaStackViewHeight"
        case tagUserListHeight = "tagUserListHeight"
        case tagStockCodeListHeight = "tagStockCodeListHeight"
    }

    @objc func tapped(button: UIButton) {
        switch button {
        case sendButton:
            //clear
            self.clearTagStockCodeList()
            let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.lengthOfBytes(using: .utf8) > 0 {
                if self.searchedKeywordInSendText(sendingText: text) == false {
                    action?(.sendText(button,text, self.getMentionUserList()))
                }
            }
            break
        case plusButton:
            action?(.more(button))
            break
        case photoButton:
            action?(.cameraButtonClicked(button))
            break
        case videoButton:
            action?(.startVideoRecord)
            break
        case attachmentButton:
            action?(.showUploadAttachmentFile)
            break
        case galleryButton:
            action?(.showImagePicker)
            break
        case locationButton:
            action?(.showLocation)
            break
        case contactButton:
            action?(.shareContact)
            break
        case joinGroupButton:
            self.delegate?.chatBarRequestJoinGroupButtonClicked(chatBar: self, chatView:nil)
            break
        case blockChatButton:
            self.delegate?.chatBarRequestBlockChatButtonClicked(chatBar: self, chatView:nil)
            break
        default: break
        }
    }

    fileprivate func toggleKeyboardType(textView: UITextView) {

        textView.keyboardType = .asciiCapable
        textView.reloadInputViews()
        textView.keyboardType = .default
        textView.reloadInputViews()
    }

    var chatIdentifier: String?
    private var pashHolderStr = ""

    private func initializeView() {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            textView.textAlignment = .right
        }

        sendButton.isHidden = false
        micButton.isHidden = true
        micButton.setAudioRecDelegate(recorderDelegate: self)
        soundRec.setAudioRecViewDelegate(recorderDelegate: self)
        textView.delegate = self
        mentionUserList.delegate = self
        mentionUserList.dataSource = self
        tagStockCodeList.delegate = self
        tagStockCodeList.dataSource = self
        backgroundColor = UIColor.ALKSVGreyColor245()
        translatesAutoresizingMaskIntoConstraints = false

        plusButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        attachmentButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        joinGroupButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        blockChatButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        
        self.placeHolder.text = self.pashHolderStr
        

        setupAttachment(buttonIcons: chatBarConfiguration.attachmentIcons)
        setupConstraints()
        self.hiddenMentionUserList(true)
        self.hiddenTagStockCodeList(true)

        //off join button
        self.hiddenJoinGroupButton()
        self.hiddenBlockChatButton(true)
        
        if configuration.hideLineImageFromChatBar {
            lineImageView.isHidden = true
        }
        updateMediaViewVisibility()
    }

    func setup(_ tableview: UITableView, withPrefex prefix: String) {
        autocompletionView = tableview
        autocompletionView.dataSource = self
        autocompletionView.delegate = self
        autoCompletionViewHeightConstraint = autocompletionView.heightAnchor.constraint(equalToConstant: 0)
        autoCompletionViewHeightConstraint?.isActive = true
        self.prefix = prefix
    }

    open func clear() {
        textView.text = ""
        clearTextInTextView()
        toggleKeyboardType(textView: textView)
        hideAutoCompletionView()
        clearMentionUserList()
        clearTagStockCodeList()
    }

    func hideMicButton() {
        self.isMicButtonHidden = true
        self.micButton.isHidden = true
        self.sendButton.isHidden = false
    }

    required public init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        self.isMicButtonHidden = configuration.hideAudioOptionInChatBar
        initializeView()
    }

    deinit {
        plusButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        photoButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        videoButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        attachmentButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        galleryButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        joinGroupButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        blockChatButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
    }

    private var isNeedInitText = true

    open override func layoutSubviews() {
        super.layoutSubviews()

        if isNeedInitText {

            guard chatIdentifier != nil else {
                return
            }

            isNeedInitText = false
        }

    }

    fileprivate var textViewHeighConstrain: NSLayoutConstraint?
    fileprivate let textViewHeigh: CGFloat = 40.0
    fileprivate let textViewHeighMax: CGFloat = 102.2 + 8.0

    fileprivate var textViewTrailingWithSend: NSLayoutConstraint?
    fileprivate var textViewTrailingWithMic: NSLayoutConstraint?
    fileprivate var autoCompletionViewHeightConstraint: NSLayoutConstraint?

    public var autoCompletionItems = [AutoCompleteItem]()
    var filteredAutocompletionItems = [AutoCompleteItem]()

    public var prefix: String?

    // swiftlint:disable:next function_body_length
    private func setupConstraints(
        maxLength: CGFloat = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)) {
        plusButton.isHidden = true

        var bottomAnchor: NSLayoutYAxisAnchor {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.bottomAnchor
            } else {
                return self.bottomAnchor
            }
        }

        var buttonSpacing: CGFloat = 25
        if maxLength <= 568.0 { buttonSpacing = 20 } // For iPhone 5

        func buttonsForOptions(_ options: ALKChatBarConfiguration.AttachmentOptions) -> [UIButton] {
            var buttons: [UIButton] = []
            switch options {
            case .all:
                for option in AttachmentType.allCases {
                    buttons.append(buttonForAttachmentType(option))
                }
            case .some(let options):
                for option in options {
                    buttons.append(buttonForAttachmentType(option))
                }
            case .none:
                print("Nothing to add")
            }
            return buttons
        }

        func buttonForAttachmentType(
            _ type: AttachmentType) -> UIButton {
            switch type {
            case .contact:
                return contactButton
            case .gallery:
                return galleryButton
            case .location:
                return locationButton
            case .camera:
                return photoButton
            case .video:
                return videoButton
            case .file:
                return attachmentButton
            }
        }

        let buttonSize = CGSize(width: 30, height: 30)
        let attachmentButtons = buttonsForOptions(chatBarConfiguration.optionsToShow)
        attachmentButtons.forEach { attachmentButtonStackView.addArrangedSubview($0) }
        attachmentButtonStackView.spacing = buttonSpacing

        addViewsForAutolayout(views: [
            headerView,
            bottomGrayView,
            plusButton,
            attachmentButtonStackView,
            grayView,
            textView,
            sendButton,
            micButton,
            lineImageView,
            lineView,
            lineBottomView,
            frameView,
            placeHolder,
            soundRec,
            mentionUserList,
            tagStockCodeList,
            joinGroupView,
            blockChatButton])
        
        lineView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        lineView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        lineBottomView.topAnchor.constraint(equalTo: grayView.bottomAnchor).isActive = true
        lineBottomView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lineBottomView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lineBottomView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        headerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.headerViewHeight.rawValue).isActive = true

        mentionUserList.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        mentionUserList.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mentionUserList.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mentionUserList.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.tagUserListHeight.rawValue).isActive = true
        
        tagStockCodeList.topAnchor.constraint(equalTo: mentionUserList.bottomAnchor).isActive = true
        tagStockCodeList.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tagStockCodeList.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tagStockCodeList.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.tagStockCodeListHeight.rawValue).isActive = true
        
        let buttonheightConstraints = attachmentButtonStackView.subviews
            .map { $0.widthAnchor.constraint(equalToConstant: buttonSize.width)}
        
        var stackViewConstraints = [
            attachmentButtonStackView.topAnchor.constraint(equalTo: bottomGrayView.topAnchor),
            attachmentButtonStackView.bottomAnchor.constraint(equalTo: bottomGrayView.bottomAnchor),
            attachmentButtonStackView.leadingAnchor.constraint(equalTo: bottomGrayView.leadingAnchor, constant: 18),
            attachmentButtonStackView.trailingAnchor.constraint(lessThanOrEqualTo: bottomGrayView.trailingAnchor, constant: -18),
            attachmentButtonStackView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.mediaStackViewHeight.rawValue)
        ]
        stackViewConstraints.append(contentsOf: buttonheightConstraints)
        NSLayoutConstraint.activate(stackViewConstraints)
        

        plusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        plusButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true

        lineImageView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -15).isActive = true
        lineImageView.widthAnchor.constraint(equalToConstant: 2).isActive = true
        lineImageView.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10).isActive = true
        lineImageView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        sendButton.centerYAnchor.constraint(equalTo:textView.centerYAnchor).isActive = true
        //sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -7).isActive = true

        micButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        micButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        micButton.centerYAnchor.constraint(equalTo:textView.centerYAnchor).isActive = true
        //micButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        if isMicButtonHidden {
            micButton.isHidden = true
        } else {
            sendButton.isHidden = true
        }

        textView.topAnchor.constraint(equalTo: tagStockCodeList.bottomAnchor, constant: 9.5).isActive = true
        textView.bottomAnchor.constraint(equalTo: grayView.bottomAnchor, constant: -9.5).isActive = true
        textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7).isActive = true
        textView.trailingAnchor.constraint(equalTo: lineImageView.leadingAnchor).isActive = true

        textViewHeighConstrain = textView.heightAnchor.constraint(equalToConstant: textViewHeigh)
        textViewHeighConstrain?.isActive = true

        placeHolder.heightAnchor.constraint(equalToConstant: 40).isActive = true
        placeHolder.centerYAnchor.constraint(equalTo: textView.centerYAnchor, constant: 0).isActive = true
        placeHolder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 0).isActive = true
        placeHolder.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 0).isActive = true

        soundRec.isHidden = true
        soundRec.topAnchor.constraint(equalTo: textView.topAnchor).isActive = true
        soundRec.bottomAnchor.constraint(equalTo: textView.bottomAnchor).isActive = true
        soundRec.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 0).isActive = true
        soundRec.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 0).isActive = true

        frameView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0).isActive = true
        frameView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: 11).isActive = true
        frameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -4).isActive = true
        frameView.rightAnchor.constraint(equalTo: rightAnchor, constant: 2).isActive = true

        grayView.topAnchor.constraint(equalTo: frameView.topAnchor, constant: 0).isActive = true
        grayView.bottomAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 0).isActive = true
        grayView.leftAnchor.constraint(equalTo: frameView.leftAnchor, constant: 0).isActive = true
        grayView.rightAnchor.constraint(equalTo: frameView.rightAnchor, constant: 0).isActive = true

        bottomGrayView.topAnchor.constraint(equalTo: grayView.bottomAnchor, constant: 0).isActive = true
        bottomGrayView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        bottomGrayView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue).isActive = true
        bottomGrayView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        bottomGrayView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true

        joinGroupView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        joinGroupView.bottomAnchor.constraint(equalTo: grayView.bottomAnchor, constant: 0).isActive = true
        joinGroupView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        joinGroupView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        
        blockChatButton.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        blockChatButton.bottomAnchor.constraint(equalTo: bottomGrayView.bottomAnchor, constant: 0).isActive = true
        blockChatButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        blockChatButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        
        self.joinGroupButton.translatesAutoresizingMaskIntoConstraints = false
        joinGroupView.addSubview(self.joinGroupButton)
        joinGroupButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        joinGroupButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        joinGroupButton.centerYAnchor.constraint(equalTo: joinGroupView.centerYAnchor, constant: 0).isActive = true
        joinGroupButton.heightAnchor.constraint(equalToConstant: 37).isActive = true
        
        bringSubviewToFront(frameView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Use this to update the visibilty of attachment options
    /// after the view has been set up.
    ///
    /// Note: If hide is false then view's visibility will be
    /// changed based on `ALKChatBarConfiguration`s `optionsToShow`
    /// value.
    public func updateMediaViewVisibility(hide: Bool = false) {
        if hide {
            isMediaViewHidden = true
            self.lineBottomView.isHidden = true
        } else if configuration.chatBar.optionsToShow != .none {
            isMediaViewHidden = false
            self.lineBottomView.isHidden = false
        }
    }

    private func changeButton() {
        if soundRec.isHidden {
            textView.isHidden = true
            soundRec.isHidden = false
            placeHolder.text = nil
            if placeHolder.isFirstResponder {
                placeHolder.resignFirstResponder()
            } else if textView.isFirstResponder {
                textView.resignFirstResponder()
            }
        } else {
            micButton.isSelected = false
            textView.isHidden = false
            soundRec.isHidden = true
            placeHolder.text = self.pashHolderStr
        }
    }

    func stopRecording() {
        soundRec.userDidStopRecording()
        micButton.isSelected = false
        textView.isHidden = false
        soundRec.isHidden = true
        placeHolder.text = self.pashHolderStr
    }

    func hideAudioOptionInChatBar() {
        guard !isMicButtonHidden else {
            micButton.isHidden = true
            return
        }
        micButton.isHidden = !textView.text.isEmpty
    }

    func toggleButtonInChatBar(hide: Bool) {
        if !isMicButtonHidden {
            self.sendButton.isHidden = hide
            self.micButton.isHidden = !hide
        }
    }

    func toggleUserInteractionForViews(enabled: Bool) {
        micButton.isUserInteractionEnabled = enabled
        sendButton.isUserInteractionEnabled = enabled
        soundRec.isUserInteractionEnabled = enabled
        photoButton.isUserInteractionEnabled = enabled
        videoButton.isUserInteractionEnabled = enabled
        attachmentButton.isUserInteractionEnabled = enabled
        locationButton.isUserInteractionEnabled = enabled
        galleryButton.isUserInteractionEnabled = enabled
        plusButton.isUserInteractionEnabled = enabled
        contactButton.isUserInteractionEnabled = enabled
        textView.isUserInteractionEnabled = enabled
    }

    func disableChat(message: String) {
        //toggleUserInteractionForViews(enabled: false)
        placeHolder.text = message
        if !soundRec.isHidden {
            cancelAudioRecording()
        }
        if textView.text != nil {
            textView.text = ""
            clearTextInTextView()
        }
    }

    func enableChat() {
        guard soundRec.isHidden else { return }
        toggleUserInteractionForViews(enabled: true)
        placeHolder.text = self.pashHolderStr
    }

    func updateTextViewHeight(textView: UITextView, text: String) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        let font = textView.font ?? UIFont.font(.normal(size: 14.0))
        let attributes = [NSAttributedString.Key.paragraphStyle: style, NSAttributedString.Key.font: font]
        let tv = UITextView(frame: textView.frame)
        tv.attributedText = NSAttributedString(string: text, attributes:attributes)

        let fixedWidth = textView.frame.size.width
        let size = tv.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))

        if let textViewHeighConstrain = self.textViewHeighConstrain, size.height != textViewHeighConstrain.constant {

            if size.height < self.textViewHeighMax {
                textViewHeighConstrain.constant = size.height > self.textViewHeigh ? size.height : self.textViewHeigh
            } else if textViewHeighConstrain.constant != self.textViewHeighMax {
                textViewHeighConstrain.constant = self.textViewHeighMax
            }

            textView.layoutIfNeeded()
        }
    }

    func setupAttachment(buttonIcons: [AttachmentType: UIImage?]) {

        func setup(
            image: UIImage?,
            to button: UIButton,
            withSize size: CGSize = CGSize(width: 30, height: 30)) {

            var image = image?.imageFlippedForRightToLeftLayoutDirection()
            image = image?.scale(with: size)
            button.setImage(image, for: .normal)
        }

        for option in AttachmentType.allCases {
            switch option {
            case .contact:
                setup(image: buttonIcons[AttachmentType.contact] ?? nil, to: contactButton)
            case .camera:
                setup(image: buttonIcons[AttachmentType.camera] ?? nil, to: photoButton)
            case .gallery:
                setup(image: buttonIcons[AttachmentType.gallery] ?? nil, to: galleryButton)
            case .video:
                setup(image: buttonIcons[AttachmentType.video] ?? nil, to: videoButton)
            case .location:
                setup(image: buttonIcons[AttachmentType.location] ?? nil, to: locationButton)
            case .file:
                setup(image: buttonIcons[AttachmentType.file] ?? nil, to: attachmentButton)
            }
        }
    }
    
    public func showJoinGroupButton(title:String?, backgroundColor:UIColor, textColor:UIColor, rightIcon:UIImage?){
        self.joinGroupView.isHidden = false
        self.updateMediaViewVisibility(hide: true)
        self.joinGroupButton.setTitle(title ?? "", for: .normal)
        self.joinGroupButton.backgroundColor = backgroundColor
        self.joinGroupButton.setTextColor(color: textColor, forState: .normal)
        if let _img = rightIcon {
            self.joinGroupButton.setImage(_img, for: .normal)
        }
        self.checkVisableAttachmentToolBar()
        self.backgroundColor = UIColor.white
        //on, off join button
        self.delegate?.chatBarRequestIsHiddenJoinGroupButton(chatBar: self, isHidden:false)
    }
    
    public func hiddenJoinGroupButton(){
        self.updateMediaViewVisibility()
        self.joinGroupView.isHidden = true
        self.joinGroupButton.setTitle("", for: .normal)
        self.joinGroupButton.setImage(nil, for: .normal)
        self.checkVisableAttachmentToolBar()
        self.backgroundColor = UIColor.ALKSVGreyColor250()
        //on, off join button
        self.delegate?.chatBarRequestIsHiddenJoinGroupButton(chatBar: self, isHidden:true)
    }
    
    public func hiddenBlockChatButton(_ hidden:Bool){
        self.blockChatButton.isHidden = hidden
        self.checkVisableAttachmentToolBar()
        //on, off join button
        self.delegate?.chatBarRequestIsHiddenBlockChatButton(chatBar: self, isHidden:true)
    }
    
    func setUpViewConfig(){
        //set PashHolder
        if let _tempPashHolder = self.delegate?.chatBarRequestGetTextViewPashHolder(chatBar: self){
            self.pashHolderStr = _tempPashHolder
        }else{
            self.pashHolderStr = ""
        }
        self.placeHolder.text = self.pashHolderStr
    }
    
    func updateWithConfig(isOpenGroup:Bool, config: ALKConfiguration){
        if isOpenGroup {
            //chatBar.hideMicButton()
        }
        if config.hideMicInChatBar {
            self.hideMicButton()
        }
        self.checkVisableAttachmentToolBar()
    }
    
    func isJoinGroup() -> Bool {
        return self.joinGroupView.isHidden == false
    }
    
    func hiddenLineView(_ isHidden:Bool){
        self.lineView.isHidden = isHidden
    }
    
    //private function
    private func checkVisableAttachmentToolBar(){
        let _isHidden = /*self.blockChatButton.isHidden == false ||*/ self.joinGroupView.isHidden == false
        self.updateMediaViewVisibility(hide: _isHidden)
    }
}

//MARK: - stockviva tag (tag user)
extension ALKChatBar {
    public func getMentionUserList() -> [(hashID:String, name:String)]? {
        let _returnObj:[(hashID:String, name:String)] = Array(self.mentionUserItems)
        return self.mentionUserItems.count > 0 ? _returnObj : nil
    }
    
    public func addMentionUser(hashID:String?, name:String?){
        guard let _hashID = hashID, let _name = name, _hashID.count > 0 && _name.count > 0  else {
            return
        }
        if self.mentionUserItems.contains(where: { $0.hashID == _hashID }) == false {
            self.updateCollectionView(isAdd: true, index: self.mentionUserItems.count) {
                self.mentionUserItems.append((hashID: _hashID, name: _name))
            }
        }
    }
    
    public func removeMentionUser(index:Int){
        guard index >= 0 && index < self.mentionUserItems.count else {
            return
        }
        self.updateCollectionView(isAdd:false, index: index) {
            self.mentionUserItems.remove(at: index)
        }
    }
    
    func hiddenMentionUserList(_ isHidden:Bool, completed:(()->())? = nil){
        guard self.mentionUserList.isHidden != isHidden else {
            completed?()
            return
        }
        self.mentionUserList.isHidden = isHidden
        UIView.animate(withDuration: 0.2, animations: {
            self.mentionUserList.constraint(withIdentifier: ConstraintIdentifier.tagUserListHeight.rawValue)?.constant = isHidden ? 0 : CGFloat(45.0)
        }) { (isSuccessful) in
            completed?()
        }
    }
    
    private func clearMentionUserList(){
        self.mentionUserItems.removeAll()
        self.mentionUserList.reloadData()
        self.hiddenMentionUserList(true)
    }
    
    private func updateCollectionView(isAdd:Bool, index:Int, progressUpdate:@escaping (()->())){
        
        //check need show the user list view
        self.hiddenMentionUserList(false, completed: {
            self.mentionUserList.performBatchUpdates({
                progressUpdate()
                if isAdd {
                    self.mentionUserList.insertItems(at: [IndexPath(item: index, section: 0)])
                }else{
                    self.mentionUserList.deleteItems(at: [IndexPath(item: index, section: 0)])
                }
            }) { (isSuccessful) in
                let _lastItemIndex = self.mentionUserItems.count - 1
                if _lastItemIndex < 0 {
                    if self.mentionUserItems.count == 0 {
                        self.hiddenMentionUserList(true, completed: {
                            self.mentionUserList.reloadData()
                        })
                        return
                    }
                    self.mentionUserList.reloadData()
                    return
                }
                self.mentionUserList.reloadData()
                //check need show the user list view
                if isAdd {
                    self.mentionUserList.selectItem(at: IndexPath(item: _lastItemIndex, section: 0), animated: true, scrollPosition: UICollectionView.ScrollPosition.right)
                }
            }
        })
    }
}

//MARK: - stockviva tag (tag stock code)
extension ALKChatBar {
    public func getTagStockCodeList() -> [(code:String, name:String)]? {
        let _returnObj:[(code:String, name:String)] = Array(self.tagStockCodeItems)
        return self.tagStockCodeItems.count > 0 ? _returnObj : nil
    }
    
    public func setTagStockCodeList(items:[(code:String, name:String)]?){
        guard let _list = items, _list.count > 0 else {
            self.tagStockCodeItems.removeAll()
            self.tagStockCodeList.reloadData()
            self.hiddenTagStockCodeList(true)
            return
        }
        //clear and remove
        self.tagStockCodeItems.removeAll()
        self.tagStockCodeList.reloadData()
        
        //reset and add item one by one
        self.tagStockCodeList.contentOffset = CGPoint.zero
        self.hiddenTagStockCodeList(false, completed: {
            //add one by one
            for item in _list {
                if self.tagStockCodeItems.contains(where: { $0.code == item.code }) == false {
                    self.updateTagStockCodeCollectionView(isAdd: true, index: self.tagStockCodeItems.count) {
                        self.tagStockCodeItems.append(item)
                    }
                }
            }
        })
    }
    
    private func hiddenTagStockCodeList(_ isHidden:Bool, completed:(()->())? = nil){
        guard self.tagStockCodeList.isHidden != isHidden else {
            completed?()
            return
        }
        self.tagStockCodeList.isHidden = isHidden
        UIView.animate(withDuration: 0.2, animations: {
            self.tagStockCodeList.constraint(withIdentifier: ConstraintIdentifier.tagStockCodeListHeight.rawValue)?.constant = isHidden ? 0 : CGFloat(60.0)
        }) { (isSuccessful) in
            completed?()
        }
    }
    
    private func clearTagStockCodeList(){
        self.cancelTimeForSearchStockCode()
        self.lastSearchStockCodeInfo = nil
        self.tagStockCodeItems.removeAll()
        self.tagStockCodeList.reloadData()
        self.hiddenTagStockCodeList(true)
    }
    
    private func updateTagStockCodeCollectionView(isAdd:Bool, index:Int, progressUpdate:@escaping (()->())){
        //check need show the list
        self.tagStockCodeList.performBatchUpdates({
            progressUpdate()
            if isAdd {
                self.tagStockCodeList.insertItems(at: [IndexPath(item: index, section: 0)])
            }else{
                self.tagStockCodeList.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        }) { (isSuccessful) in
            //none
       }
    }
    
    //input text
    private func startTimeForSearchStockCode(searchKey:String){
        self.searchStockCodeTimer?.invalidate()
        self.searchStockCodeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
            self.setTagStockCodeList(items: self.delegate?.chatBarRequestSearchStockCode(key: searchKey as String))
        }
    }
    
    private func cancelTimeForSearchStockCode(){
        self.searchStockCodeTimer?.invalidate()
        self.searchStockCodeTimer = nil
    }
    
    private func searchStockCodeWhenInputText(finalText:String, enteredText:String, startIndex:Int, lengthOfChange:Int){
        guard finalText.count > 0 else {//no text no search
            self.clearTagStockCodeList()
            return
        }
        let _isDeleteAction = enteredText.count == 0 && lengthOfChange > 0
        let _isIntValue = Int(enteredText) != nil
        var _lastUserEnteredForSearchStockCode:(startIndex:Int, length:Int)? = nil
        if let _searchInfo = self.lastSearchStockCodeInfo {
            _lastUserEnteredForSearchStockCode = (startIndex:_searchInfo.range.location, length:_searchInfo.range.length)
        }
        
        if let _lastEnteredInfo = _lastUserEnteredForSearchStockCode {
            let _maxOfSavedLength = _lastEnteredInfo.startIndex + _lastEnteredInfo.length
            let _endIndexOfNewStr = (startIndex + lengthOfChange) - 1
            let _maxOfSavedIndex = _maxOfSavedLength - 1
            if startIndex >= _lastEnteredInfo.startIndex && startIndex <= (_maxOfSavedIndex + 1) {
                if _isDeleteAction {//if delete
                    let _newLength = _lastEnteredInfo.length - lengthOfChange
                    if _newLength <= 0 {
                         _lastUserEnteredForSearchStockCode = nil
                    }else{
                        _lastUserEnteredForSearchStockCode?.length = _newLength
                    }
                }else if _isIntValue {
                    let _newLength = _lastEnteredInfo.length + enteredText.count
                    _lastUserEnteredForSearchStockCode?.length = _newLength
                }else {
                    _lastUserEnteredForSearchStockCode = nil
                }
            }else {
                if _isDeleteAction {
                    if startIndex >= 0 && startIndex < _lastEnteredInfo.startIndex {
                        if _endIndexOfNewStr < _maxOfSavedIndex {
                            let _newLength = _maxOfSavedIndex - _endIndexOfNewStr
                            _lastUserEnteredForSearchStockCode = (startIndex: startIndex, length:_newLength)
                        }else{
                            _lastUserEnteredForSearchStockCode = nil
                        }
                    }
                }else if _isIntValue {
                    _lastUserEnteredForSearchStockCode = (startIndex:startIndex, length:enteredText.count)
                }else {
                    _lastUserEnteredForSearchStockCode = nil
                }
            }
        }else {
            if _isIntValue && _isDeleteAction == false {
                _lastUserEnteredForSearchStockCode = (startIndex:startIndex, length:enteredText.count)
            }
        }
        
        if let _lastEnteredInfo = _lastUserEnteredForSearchStockCode {
            let _range = NSMakeRange(_lastEnteredInfo.startIndex, _lastEnteredInfo.length )
            var _targetSearchStr = finalText as NSString
            _targetSearchStr = _targetSearchStr.substring(with: _range) as NSString
            self.lastSearchStockCodeInfo = (text:_targetSearchStr as String, range:_range)
            self.startTimeForSearchStockCode(searchKey:_targetSearchStr as String)
        }else{
            self.clearTagStockCodeList()
        }
    }
    
    public func didClickedSearchStockCodeResultInList(code:String, name:String, lastSearchStockCodeInfo:(text:String, range:NSRange)?){
        //click call back
        self.delegate?.chatBarRequestSuggestionStockCodeClicked(code: code, name: name)
        //do add text in input field
        guard let _searchedInfo = lastSearchStockCodeInfo,
            let codeLinkFormatStr = ALKConfiguration.ConversationMessageLinkType.stockCode(isNameOnly: false).getInputDisplayFormat(value: code) else {
            return
        }
        let _displayText = self.textView.text as NSString
        var _result:NSString = _displayText.replacingCharacters(in: _searchedInfo.range, with: codeLinkFormatStr) as NSString
        
        let _checkPerChar1 = _searchedInfo.range.location - 1
        let _checkPerChar2 = _searchedInfo.range.location - 2
        if _checkPerChar1 >= 0 && _checkPerChar1 < _result.length {
            let _pChat1 = String(_result.substring(with: NSMakeRange(_checkPerChar1, 1)))
            if _pChat1 == ALKConfiguration.ConversationMessageLinkType.stockCode(isNameOnly: false).getKeyStr() {
                if _checkPerChar2 >= 0 && _checkPerChar2 < _result.length {
                    if Int(_result.substring(with: NSMakeRange(_checkPerChar2, 1))) == nil {
                        _result = _result.replacingCharacters(in: NSMakeRange(_checkPerChar1, 1), with: "") as NSString
                    }
                }else{
                    _result = _result.replacingCharacters(in: NSMakeRange(_checkPerChar1, 1), with: "") as NSString
                }
            }
        }
        
        self.textView.text = _result as String
        self.clearTagStockCodeList()
    }
}

extension ALKChatBar {
    private func searchedKeywordInSendText(sendingText:String) -> Bool {
        var _result = false
        for matchItem in ALKConfiguration.chatMessageKeywordDetectList {
            do{
                let _regex = try NSRegularExpression(pattern:matchItem.match, options: NSRegularExpression.Options.caseInsensitive)
                let _searchedTextList = _regex.matches(in: sendingText, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: sendingText.count))
                if _searchedTextList.count > 0 {
                    _result = self.delegate?.chatBarRequestSendContentDetectedSpecialKeyword(type: matchItem.type, content: sendingText) ?? false
                    break
                }
            }catch {
            }
        }
        return _result
    }
}

extension ALKChatBar: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
        if self.configuration.chatBoxSpecialCharacterKeyCheckingList.contains(string) {
            self.delegate?.chatBarRequestUserEnteredSpecialCharacterKeyDetected(key: string)
            return false
        }
        
        guard var text = textView.text as NSString? else {
            return true
        }
        text = text.replacingCharacters(in: range, with: string) as NSString
        self.searchStockCodeWhenInputText(finalText:text as String, enteredText:string, startIndex: range.location, lengthOfChange:range.length)
        updateTextViewHeight(textView: textView, text: text as String)
        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.placeHolder.isHidden = !textView.text.isEmpty
        self.placeHolder.alpha = textView.text.isEmpty ? 1.0 : 0.0

        toggleButtonInChatBar(hide: textView.text.isEmpty)
        if showAutosuggestionsForText(textView.text, withPrefix: prefix ?? "") {
            updateAutocompletionFor(text: String(textView.text.dropFirst()))
        } else {
            hideAutoCompletionView()
        }
        if let selectedTextRange = textView.selectedTextRange {
            let line = textView.caretRect(for: selectedTextRange.start)
            let overflow = line.origin.y + line.size.height  - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top )

            if overflow > 0 {
                var offset = textView.contentOffset
                offset.y += overflow + 8.2 // leave 8.2 pixels margin

                textView.setContentOffset(offset, animated: false)
            }
        }
        action?(.chatBarTextChange(photoButton))
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        action?(.chatBarTextBeginEdit)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {

        if textView.text.isEmpty {
            toggleButtonInChatBar(hide: true)
            if self.placeHolder.isHidden {
                self.placeHolder.isHidden = false
                self.placeHolder.alpha = 1.0

                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else { return }

                    weakSelf.textViewHeighConstrain?.constant = weakSelf.textViewHeigh
                    UIView.animate(withDuration: 0.15) {
                        weakSelf.layoutIfNeeded()
                    }
                }
            }
        }

        //clear inputview of textview
        textView.inputView = nil
        textView.reloadInputViews()
    }

    fileprivate func clearTextInTextView() {
        if textView.text.isEmpty {
            toggleButtonInChatBar(hide: true)
            if self.placeHolder.isHidden {
                self.placeHolder.isHidden = false
                self.placeHolder.alpha = 1.0

                textViewHeighConstrain?.constant = textViewHeigh
                layoutIfNeeded()
            }
        }
        textView.inputView = nil
        textView.reloadInputViews()
    }
    
    public func resignAllResponderFromTextView(){
        placeHolder.resignFirstResponder()
        textView.resignFirstResponder()
    }

    func showAutoCompletionView() {
        let contentHeight = autocompletionView.contentSize.height

        let bottomPadding: CGFloat = contentHeight > 0 ? 25:0
        let maxheight: CGFloat = 200
        autoCompletionViewHeightConstraint?.constant = contentHeight < maxheight ? contentHeight+bottomPadding : maxheight
    }

    func hideAutoCompletionView() {
        autoCompletionViewHeightConstraint?.constant = 0
    }

    func showAutosuggestionsForText(_ text: String, withPrefix prefix: String) -> Bool {
        guard !prefix.isEmpty, text.starts(with: prefix) else { return false }
        if text.count > 1, text[1] == " " { return false }
        return true
    }
}

extension ALKChatBar: ALKAudioRecorderProtocol {

    public func startRecordingAudio() {
        changeButton()
        action?(.startVoiceRecord)
        soundRec.userDidStartRecording()
    }

    public func finishRecordingAudio(soundData: NSData) {
        textView.resignFirstResponder()
        if soundRec.isRecordingTimeSufficient() {
            action?(.sendVoice(soundData))
        }
        stopRecording()
    }

    public func cancelRecordingAudio() {
        stopRecording()
    }

    public func permissionNotGrant() {
        action?(.noVoiceRecordPermission)
    }

    public func moveButton(location: CGPoint) {
        soundRec.moveView(location: location)
    }
}

extension ALKChatBar: ALKAudioRecorderViewProtocol {

    public func cancelAudioRecording() {
        micButton.cancelAudioRecord()
        stopRecording()
    }
}
