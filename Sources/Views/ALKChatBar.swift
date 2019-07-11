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
    
    var delegate:ConversationChatBarActionDelegate?

    public var isMicButtonHidden: Bool!

    public enum ButtonMode {
        case send
        case media
    }

    public enum ActionType {
        case sendText(UIButton,String)
        case chatBarTextBeginEdit()
        case chatBarTextChange(UIButton)
        case sendVoice(NSData)
        case startVideoRecord()
        case startVoiceRecord()
        case showImagePicker()
        case showLocation()
        case noVoiceRecordPermission()
        case mic(UIButton)
        case more(UIButton)
        case cameraButtonClicked(UIButton)
        case shareContact()
    }

    public var action: ((ActionType) -> Void)?

    open var poweredByMessageLabel: ALKHyperLabel = {
        let label = ALKHyperLabel(frame: CGRect.zero)
        label.backgroundColor = UIColor.darkGray
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

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

    open let textView: ALKChatBarTextView = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        let tv = ALKChatBarTextView()
        tv.setBackgroundColor(UIColor.SVGreyColor245())
        tv.scrollsToTop = false
        tv.autocapitalizationType = .sentences
        tv.accessibilityIdentifier = "chatTextView"
        tv.typingAttributes = [NSAttributedString.Key.paragraphStyle: style, NSAttributedString.Key.font: UIFont.font(.normal(size: 16.0))]
        tv.layer.cornerRadius = 37.0 / 2.0
        tv.layer.borderColor = UIColor.SVGreyColor207().cgColor
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
        view.backgroundColor = UIColor.white
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy open var placeHolder: UITextView = {
        let view = UITextView()
        view.setFont(UIFont.font(.normal(size: 16)))
        view.setTextColor(UIColor.SVGreyColor153())
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
        var image = UIImage(named: "photo", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        bt.setImage(image, for: .normal)
        return bt
    }()

    open var galleryButton: UIButton = {
        let button = UIButton(type: .custom)
        var image = UIImage(named: "gallery", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        button.setImage(image, for: .normal)
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
        var image = UIImage(named: "location_new", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        bt.setImage(image, for: .normal)
        return bt
    }()

    open var contactButton: UIButton = {
        let button = UIButton(type: .custom)
        var image = UIImage(named: "contactShare", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        button.setImage(image, for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
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
        view.backgroundColor = UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
        return view
    }()

    open var bottomGrayView: UIView = {
        let view = UIView()
        view.setBackgroundColor(UIColor.SVGreyColor245())
        view.isUserInteractionEnabled = false
        return view
    }()

    open var videoButton: UIButton = {
        let button = UIButton(type: .custom)
        var image = UIImage(named: "video", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        button.setImage(image, for: .normal)
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
        view.backgroundColor = UIColor.SVStockColorRed()
        view.setTitleColor(UIColor.white, for: .normal)
        view.setFont(font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        view.titleLabel?.textAlignment = .center
        view.semanticContentAttribute = .forceRightToLeft
        view.layer.cornerRadius = 18.5
        return view
    }()
    
    /// Returns true if the textView is first responder.
    open var isTextViewFirstResponder: Bool {
        return textView.isFirstResponder
    }

    private enum ConstraintIdentifier: String {
        case mediaBackgroudViewHeight = "mediaBackgroudViewHeight"
        case poweredByMessageHeight = "poweredByMessageHeight"
        case headerViewHeight = "headerViewHeight"
    }

    @objc func tapped(button: UIButton) {
        switch button {
        case sendButton:
            let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.lengthOfBytes(using: .utf8) > 0 {
                action?(.sendText(button,text))
            }
            break
        case plusButton:
            action?(.more(button))
            break
        case photoButton:
            action?(.cameraButtonClicked(button))
            break

        case videoButton:
            action?(.startVideoRecord())
            break
        case galleryButton:
            action?(.showImagePicker())
            break
        case locationButton:
            action?(.showLocation())
        case contactButton:
            action?(.shareContact())
        case joinGroupButton:
            self.delegate?.joinGroupButtonClicked(chatBar: self, chatView:nil)
        default: break

        }
    }

    fileprivate func toggleKeyboardType(textView: UITextView) {

        textView.keyboardType = .asciiCapable
        textView.reloadInputViews()
        textView.keyboardType = .default
        textView.reloadInputViews()
    }

    private weak var comingSoonDelegate: UIView?

    var chatIdentifier: String?
    private var pashHolderStr = ""

    private func initializeView() {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            textView.textAlignment = .right
        }
        backgroundColor = UIColor.SVGreyColor245()

        micButton.setAudioRecDelegate(recorderDelegate: self)
        soundRec.setAudioRecViewDelegate(recorderDelegate: self)
        textView.delegate = self
        backgroundColor = UIColor.SVGreyColor245()
        translatesAutoresizingMaskIntoConstraints = false

        plusButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        joinGroupButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        
        //set PashHolder
        if let _tempPashHolder = self.delegate?.getTextViewPashHolder(chatBar: self){
            self.pashHolderStr = _tempPashHolder
        }else{
            self.pashHolderStr = ""
        }
        self.placeHolder.text = self.pashHolderStr
        
        setupConstraints()

        //off join button
        self.hiddenJoinGroupButton()
        //on, off join button
        self.delegate?.processOnOffJoinGroupButton(chatBar: self)
        
        if configuration.hideLineImageFromChatBar {
            lineImageView.isHidden = true
        }
    }

    func setup(_ tableview: UITableView, withPrefex prefix: String) {
        autocompletionView = tableview
        autocompletionView.dataSource = self
        autocompletionView.delegate = self
        autoCompletionViewHeightConstraint = autocompletionView.heightAnchor.constraint(equalToConstant: 0)
        autoCompletionViewHeightConstraint?.isActive = true
        self.prefix = prefix
    }

    func setComingSoonDelegate(delegate: UIView) {
        comingSoonDelegate = delegate
    }

    open func clear() {
        textView.text = ""
        clearTextInTextView()
        toggleKeyboardType(textView: textView)
        hideAutoCompletionView()
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
        galleryButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        joinGroupButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
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
    fileprivate let textViewHeigh: CGFloat = 37.0
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

        var buttonSpacing: CGFloat = 30
        if maxLength <= 568.0 { buttonSpacing = 20 } // For iPhone 5

        addViewsForAutolayout(views: [
            headerView,
            bottomGrayView,
            plusButton,
            photoButton,
            grayView,
            textView,
            sendButton,
            micButton,
            lineImageView,
            videoButton,
            galleryButton,
            locationButton,
            contactButton,
            lineView,
            frameView,
            placeHolder,
            soundRec,
            poweredByMessageLabel,
            joinGroupView])
        
        lineView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        lineView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        headerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.headerViewHeight.rawValue).isActive = true

        contactButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        let photoLeadingSpace: CGFloat!
        if configuration.hideContactInChatBar {
            contactButton.widthAnchor.constraint(equalToConstant: 0).isActive = true
            contactButton.isHidden = true
            photoLeadingSpace = 0
        } else {
            contactButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            contactButton.isHidden = false
            photoLeadingSpace = buttonSpacing
        }
        contactButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        contactButton.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor, constant: 0).isActive = true

        photoButton.leadingAnchor.constraint(equalTo: contactButton.trailingAnchor, constant: photoLeadingSpace).isActive = true
        photoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        photoButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        photoButton.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor, constant: 0).isActive = true

        plusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 38).isActive = true
        plusButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true

        videoButton.leadingAnchor.constraint(equalTo: galleryButton.trailingAnchor, constant: buttonSpacing).isActive = true
        videoButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        videoButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        videoButton.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor, constant: 0).isActive = true

        galleryButton.leadingAnchor.constraint(equalTo: photoButton.trailingAnchor, constant: buttonSpacing).isActive = true
        galleryButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        galleryButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        galleryButton.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor, constant: 0).isActive = true

        locationButton.leadingAnchor.constraint(equalTo: videoButton.trailingAnchor, constant: buttonSpacing).isActive = true
        locationButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        locationButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        locationButton.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor, constant: 0).isActive = true

        lineImageView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -15).isActive = true
        lineImageView.widthAnchor.constraint(equalToConstant: 2).isActive = true
        lineImageView.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10).isActive = true
        lineImageView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -7).isActive = true

        micButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        micButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        micButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        if isMicButtonHidden {
            micButton.isHidden = true
        } else {
            sendButton.isHidden = true
        }

        textView.topAnchor.constraint(equalTo: poweredByMessageLabel.bottomAnchor, constant: 11).isActive = true
        textView.bottomAnchor.constraint(equalTo: grayView.bottomAnchor, constant: -11).isActive = true
        textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7).isActive = true
        poweredByMessageLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        poweredByMessageLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        poweredByMessageLabel.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.poweredByMessageHeight.rawValue).isActive = true
        poweredByMessageLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true

        textView.trailingAnchor.constraint(equalTo: lineImageView.leadingAnchor).isActive = true

        textViewHeighConstrain = textView.heightAnchor.constraint(equalToConstant: textViewHeigh)
        textViewHeighConstrain?.isActive = true

        placeHolder.heightAnchor.constraint(equalToConstant: 37).isActive = true
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

    public func hideMediaView() {
        bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 0
        galleryButton.isHidden = true
        locationButton.isHidden = true
        hideAudioOptionInChatBar()
        photoButton.isHidden = true
        contactButton.isHidden = true
        videoButton.isHidden = true
    }

    public func showMediaView() {
        bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 45
        galleryButton.isHidden = false
        locationButton.isHidden = false
        hideAudioOptionInChatBar()
        photoButton.isHidden = false
        contactButton.isHidden = false
        videoButton.isHidden = false
    }

    public func showPoweredByMessage() {
        poweredByMessageLabel.constraint(withIdentifier: ConstraintIdentifier.poweredByMessageHeight.rawValue)?.constant = 20
    }

    private func changeButton() {
        if soundRec.isHidden {
            soundRec.isHidden = false
            placeHolder.text = nil
            if placeHolder.isFirstResponder {
                placeHolder.resignFirstResponder()
            } else if textView.isFirstResponder {
                textView.resignFirstResponder()
            }
        } else {
            micButton.isSelected = false
            soundRec.isHidden = true
            placeHolder.text = self.pashHolderStr
        }
    }

    func stopRecording() {
        soundRec.userDidStopRecording()
        micButton.isSelected = false
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
        locationButton.isUserInteractionEnabled = enabled
        galleryButton.isUserInteractionEnabled = enabled
        plusButton.isUserInteractionEnabled = enabled
        contactButton.isUserInteractionEnabled = enabled
        textView.isUserInteractionEnabled = enabled
    }

    func disableChat(message: String) {
        toggleUserInteractionForViews(enabled: false)
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
    
    func showJoinGroupButton(title:String?, backgroundColor:UIColor, textColor:UIColor, rightIcon:UIImage?){
        self.joinGroupView.isHidden = false
        self.hideMediaView()
        self.joinGroupButton.setTitle(title ?? "", for: .normal)
        self.joinGroupButton.backgroundColor = backgroundColor
        self.joinGroupButton.setTextColor(color: textColor, forState: .normal)
        if let _img = rightIcon {
            self.joinGroupButton.setImage(_img, for: .normal)
        }
    }
    
    func hiddenJoinGroupButton(){
        self.showMediaView()
        self.joinGroupView.isHidden = true
        self.joinGroupButton.setTitle("", for: .normal)
        self.joinGroupButton.setImage(nil, for: .normal)
    }
    
    func updateWithConfig(isOpenGroup:Bool, config: ALKConfiguration){
//        if isOpenGroup {
//            hideMediaView()
//            hideMicButton()
//        } else {
            if self.joinGroupView.isHidden == false {
                hideMediaView()
            }else{
                if config.hideAllOptionsInChatBar {
                    hideMediaView()
                } else {
                    showMediaView()
                }
            }
//        }
    }
    
    func isJoinGroup() -> Bool {
        return self.joinGroupView.isHidden == false
    }
}

extension ALKChatBar: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
        guard var text = textView.text as NSString? else {
            return true
        }

        text = text.replacingCharacters(in: range, with: string) as NSString
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
        action?(.chatBarTextBeginEdit())
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
        action?(.startVoiceRecord())
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
        action?(.noVoiceRecordPermission())
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
