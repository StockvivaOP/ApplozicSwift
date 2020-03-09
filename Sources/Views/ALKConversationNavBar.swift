//
//  ALKConversationNavBar.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 25/02/19.
//

import Foundation
import Kingfisher

protocol NavigationBarCallbacks: class {
    func backButtonTapped()
    func titleTapped()
    func getTitle() -> String?
}

class ALKConversationNavBar: UIView, Localizable {

    let navigationBarBackgroundColor: UIColor
    let configuration: ALKConfiguration
    weak var delegate: NavigationBarCallbacks?
    var disableTitleAction: Bool = false

    let backButton: UIButton = {
        let view = UIButton()
        view.accessibilityIdentifier = "conversationBackButton"
        view.backgroundColor = .clear
        return view
    }()

    let backImage: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "back", in: Bundle.applozic, compatibleWith: nil)
        view.isUserInteractionEnabled = false
        return view
    }()

    var profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.isHidden = true
        return imageView
    }()

    var profileName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .medium) //UIFont(name: "HelveticaNeue", size: 16) ?? UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.white //UIColor(96, green: 94, blue: 94)
        label.textAlignment = .left
        return label
    }()
    
    var groupMuteImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "sv_icon_chatrrom_mute", in: Bundle.applozic, compatibleWith: nil)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    var actionRemark: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor.ALKSVColorPurpleD9DBFF()
        label.textAlignment = .left
        return label
    }()
    
    lazy var statusIconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = self.navigationBarBackgroundColor
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()

    var onlineStatusIcon: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(165, green: 170, blue: 165)
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        return view
    }()

    var onlineStatusText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12) //UIFont(name: "HelveticaNeue", size: 12) ?? UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white //UIColor(113, green: 110, blue: 110)
        return label
    }()

    lazy var profileNameView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.profileName, self.groupMuteImage])
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 5
        return stackView
    }()
    
    lazy var profileView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.profileNameView, self.onlineStatusText])
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        stackView.isHidden = true
        return stackView
    }()

    required init(configuration: ALKConfiguration, delegate: NavigationBarCallbacks) {
        self.navigationBarBackgroundColor = configuration.navigationBarBackgroundColor
        self.configuration = configuration
        self.delegate = delegate
        super.init(frame: .zero)
        setupConstraints()
        setupStyle()
        setupActions()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(profile: ALKConversationProfile) {
        profileView.isHidden = false
        setupProfile(name: profile.name, imageUrl: profile.imageUrl, isContact: (profile.status != nil))
        guard let status = profile.status, !profile.isBlocked else {
            self.hideStatus(true)
            return
        }
        self.hideStatus(false)
        updateStatus(isOnline: status.isOnline, lastSeenAt: status.lastSeenAt)
    }
    
    func updateContent(){
        profileName.text = delegate?.getTitle() ?? profileName.text
        self.actionRemark.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chatgroup_top_bar_subtitle") ?? ""
    }

    func updateStatus(isOnline: Bool, lastSeenAt: NSNumber?) {
        if isOnline {
            onlineStatusText.text = localizedString(forKey: "Online", withDefaultValue: SystemMessage.UserStatus.Online, fileName: configuration.localizedStringFileName)
            onlineStatusIcon.backgroundColor = UIColor(28, green: 222, blue: 20)
        } else {
            showLastSeen(lastSeenAt)
            onlineStatusIcon.backgroundColor = UIColor(165, green: 170, blue: 165)
        }
    }
    
    @objc func backButtonTapped() {
        delegate?.backButtonTapped()
    }

    @objc func titleTapped() {
        guard !disableTitleAction else { return }
        delegate?.titleTapped()
    }

    private func setupConstraints() {
        statusIconBackground.addViewsForAutolayout(views: [onlineStatusIcon])
        self.addViewsForAutolayout(views: [backImage, backButton, profileImage, statusIconBackground, profileView, actionRemark])

        //Setup constraints
        backButton.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        backButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        backButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 30).isActive = true

        backImage.leadingAnchor.constraint(equalTo: backButton.leadingAnchor, constant: 5).isActive = true
        backImage.centerYAnchor.constraint(equalTo: backButton.centerYAnchor).isActive = true
        backImage.widthAnchor.constraint(equalToConstant: 10).isActive = true
        backImage.heightAnchor.constraint(equalToConstant: 24).isActive = true

        profileImage.leadingAnchor.constraint(equalTo: backButton.trailingAnchor).isActive = true
        profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        profileImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        profileImage.widthAnchor.constraint(equalToConstant: 35).isActive = true

        statusIconBackground.bottomAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: -2).isActive = true
        statusIconBackground.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: -5).isActive = true
        statusIconBackground.widthAnchor.constraint(equalToConstant: 12).isActive = true
        statusIconBackground.heightAnchor.constraint(equalToConstant: 12).isActive = true

        onlineStatusIcon.centerXAnchor.constraint(equalTo: statusIconBackground.centerXAnchor).isActive = true
        onlineStatusIcon.centerYAnchor.constraint(equalTo: statusIconBackground.centerYAnchor).isActive = true
        onlineStatusIcon.widthAnchor.constraint(equalToConstant: 10).isActive = true
        onlineStatusIcon.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        profileView.leadingAnchor.constraint(equalTo: statusIconBackground.trailingAnchor, constant: 5).isActive = true
        profileView.topAnchor.constraint(equalTo: profileImage.topAnchor, constant: -2.5).isActive = true
        profileView.bottomAnchor.constraint(equalTo: actionRemark.topAnchor).isActive = true
        profileView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        profileView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        actionRemark.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 0).isActive = true
        actionRemark.topAnchor.constraint(equalTo: profileView.bottomAnchor, constant: 5).isActive = true
        actionRemark.bottomAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 2.5).isActive = true
        actionRemark.trailingAnchor.constraint(equalTo: profileView.trailingAnchor).isActive = true
        actionRemark.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        groupMuteImage.widthAnchor.constraint(equalToConstant: 15).isActive = true
        groupMuteImage.heightAnchor.constraint(equalToConstant: 15).isActive = true
    }

    private func hideStatus(_ hide: Bool) {
        statusIconBackground.isHidden = hide
        onlineStatusText.isHidden = hide
    }

    private func setupStyle() {
        backImage.tintColor = configuration.navigationBarItemColor
        profileName.textColor = configuration.navigationBarTitleColor
        onlineStatusText.textColor = configuration.navigationBarTitleColor
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        let tapAction = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        tapAction.numberOfTapsRequired = 1
        profileView.addGestureRecognizer(tapAction)
    }

    private func setupProfile(name: String, imageUrl: String?, isContact: Bool) {
        var _title = delegate?.getTitle() ?? name
        profileName.text = _title

        let placeholderName = isContact ?  "contactPlaceholder" : "groupPlaceholder"
        let placeholder = UIImage(named: placeholderName, in: Bundle.applozic, compatibleWith: nil)
        guard
            let urlString = imageUrl,
            let url = URL(string: urlString)
            else {
                self.profileImage.image = placeholder
                return
        }
        let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
        profileImage.kf.setImage(with: resource, placeholder: placeholder)
    }

    private func showLastSeen(_ lastSeenAt: NSNumber?) {
        guard let lastSeenAt = lastSeenAt else {
            onlineStatusText.isHidden = true
            return
        }
        let currentTime = Date()
        let lastSeen = Double(exactly: lastSeenAt) ?? 0.0
        let lastOnlineTime = Date(timeIntervalSince1970: lastSeen/1000)
        let difference = currentTime.timeIntervalSince(lastOnlineTime)
        var status: String = ""
        if difference < 60.0 { // Less than 1 minute
            status = localizedString(forKey: "JustNow", withDefaultValue: SystemMessage.UserStatus.JustNow, fileName: configuration.localizedStringFileName)
        } else if difference < 60.0 * 60.0 { // Less than 1 hour
            let minutes = (difference.truncatingRemainder(dividingBy: 3600)) / 60
            let format = localizedString(forKey: "MinutesAgo",
                                         withDefaultValue: SystemMessage.UserStatus.MinutesAgo,
                                         fileName: configuration.localizedStringFileName)
            status = String(format: format, String(format: "%.0f", minutes))
        } else if difference < 60.0 * 60.0 * 24 { // Less than 1 day
            let hours = difference / 3600
            let format = localizedString(forKey: "HoursAgo",
                                         withDefaultValue: SystemMessage.UserStatus.HoursAgo,
                                         fileName: configuration.localizedStringFileName)
            status = String(format: format, String(format: "%.0f", hours))
        } else {
            let format = DateFormatter()
            format.dateFormat = "EE, MMM dd, yyy"
            status = format.string(from: lastOnlineTime)
        }
        let lastSeenFormat = localizedString(forKey: "LastSeen",
                                             withDefaultValue: SystemMessage.UserStatus.LastSeen,
                                             fileName: configuration.localizedStringFileName)
        onlineStatusText.text = String(format: lastSeenFormat, status)
    }

}
