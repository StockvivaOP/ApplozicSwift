//
//  ALKMediaViewerViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 24/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import AVFoundation
import Kingfisher
import AVKit

final class ALKMediaViewerViewController: UIViewController {

    // to be injected
    var viewModel: ALKMediaViewerViewModel?

    @IBOutlet private weak var fakeView: UIView!

    fileprivate let scrollView: UIScrollView = {
        let sv = UIScrollView(frame: .zero)
        sv.backgroundColor = UIColor.black
        sv.isUserInteractionEnabled = true
        sv.isScrollEnabled = true
        sv.zoomScale = 0.0
        sv.minimumZoomScale = 1
        sv.maximumZoomScale = 3
        sv.bounces = false
        return sv
    }()

    fileprivate let imageView: UIImageView = {
        let mv = UIImageView(frame: .zero)
        mv.contentMode = .scaleToFill
        mv.backgroundColor = UIColor.clear
        mv.isUserInteractionEnabled = false
        return mv
    }()

    fileprivate let playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PLAY", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate let audioPlayButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "audioPlay", in: Bundle.applozic, compatibleWith: nil)
        button.imageView?.tintColor = UIColor.gray
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate let audioIcon: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(named: "mic", in: Bundle.applozic, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let loadingIndicator: CustomActivityIndicatorView = {
        let _view = CustomActivityIndicatorView(frame: .zero)
        _view.style = .whiteLarge
        _view.backgroundColor = UIColor.darkGray
        _view.layer.cornerRadius = 5.0
        _view.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        _view.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        _view.hidesWhenStopped = true
        return _view
    }()

    private weak var imageViewBottomConstraint: NSLayoutConstraint?
    private weak var imageViewTopConstraint: NSLayoutConstraint?
    private weak var imageViewTrailingConstraint: NSLayoutConstraint?
    private weak var imageViewLeadingConstraint: NSLayoutConstraint?
    
    private var isFirstLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        setupView()
    }

    private func setupNavigation() {
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        guard let navVC = self.navigationController else {return}
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        viewModel?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isFirstLoad {
            guard let message = viewModel?.getMessageForCurrentIndex() else { return }
            updateView(message: message)
            self.isFirstLoad = false
        }
    }
    
    fileprivate func setupView() {
        playButton.addTarget(self, action: #selector(ALKMediaViewerViewController.playButtonAction(_:)), for: .touchUpInside)
        audioPlayButton.addTarget(self, action: #selector(ALKMediaViewerViewController.audioPlayButtonAction(_:)), for: .touchUpInside)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ALKMediaViewerViewController.swipeRightAction)) // put : at the end of method name
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ALKMediaViewerViewController.swipeLeftAction))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        view.addViewsForAutolayout(views: [scrollView, playButton, audioPlayButton, audioIcon, loadingIndicator])
        scrollView.bringSubviewToFront(playButton)
        view.bringSubviewToFront(audioPlayButton)
        view.bringSubviewToFront(audioIcon)
        scrollView.addSubview(imageView)

        playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        if #available(iOS 11.0, *) {
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }

        audioPlayButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        audioPlayButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        audioPlayButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        audioPlayButton.widthAnchor.constraint(equalToConstant: 100).isActive = true

        audioIcon.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        audioIcon.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        audioIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        audioIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true

        view.layoutIfNeeded()
    }

    @IBAction private func dismissPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func swipeRightAction() {
        viewModel?.updateCurrentIndex(by: -1)
    }

    @objc private func swipeLeftAction() {
        viewModel?.updateCurrentIndex(by: +1)
    }
    
    func showPhotoView(message: ALKMessageViewModel) {
        self.imageView.image = nil
        if let filePath = message.filePath,
            let url = viewModel?.getURLFor(name: filePath) {
            let provider = LocalFileImageDataProvider(fileURL: url)
            imageView.kf.setImage(with: provider) { (result) in
                switch result {
                case .success(let value):
                    //cal zoom size
                    self.resetScrollImageStatus(imgSize: value.image.size)
                    break
                case .failure(_):
                    //none action
                    break
                }
            }
        }else if let fileUrlPath = message.imageURL {
            imageView.kf.indicatorType = .custom(indicator: self.loadingIndicator)
            imageView.kf.setImage(with: fileUrlPath) { (result) in
                switch result {
                case .success(let value):
                    //cal zoom size
                    self.resetScrollImageStatus(imgSize: value.image.size)
                    break
                case .failure(_):
                    //none action
                    break
                }
            }
        }else {
            self.loadingIndicator.startAnimating()
            viewModel?.fetchMessageWithId(messageId: message.identifier, completed: { (msgList) in
                self.loadingIndicator.stopAnimating()
                if let _msg = msgList?[0] {
                    self.viewModel?.replaceCurrentMessage(message: _msg)
                    self.showPhotoView(message:_msg.messageModel)
                }
            })
            return
        }
        
        //imageView.sizeToFit()
        playButton.isHidden = true
        audioPlayButton.isHidden = true
        audioIcon.isHidden = true
    }

    func showVideoView(message: ALKMessageViewModel) {
        guard let filePath = message.filePath,
            let url = viewModel?.getURLFor(name: filePath) else { return }
        imageView.image = viewModel?.getThumbnail(filePath: url)
        imageView.sizeToFit()
        playButton.isHidden = false
        audioPlayButton.isHidden = true
        audioIcon.isHidden = true
        guard let viewModel = viewModel,
            viewModel.isAutoPlayTrueForCurrentIndex() else { return }
        playVideo()
        viewModel.currentIndexAudioVideoPlayed()
    }

    func showAudioView(message: ALKMessageViewModel) {
        imageView.image = nil
        audioPlayButton.isHidden = false
        playButton.isHidden = true
        audioIcon.isHidden = false
        guard let viewModel = viewModel,
            viewModel.isAutoPlayTrueForCurrentIndex() else { return }
        playAudio()
        viewModel.currentIndexAudioVideoPlayed()
    }

    fileprivate func updateView(message: ALKMessageViewModel) {
        guard let viewModel = viewModel else { return }
        switch message.messageType {
        case .photo:
            print("Photo type")
            updateTitle(title: viewModel.getTitle())
            showPhotoView(message: message)
        case .video:
            print("Video type")
            updateTitle(title: viewModel.getTitle())
            showVideoView(message: message)
        case .voice:
            print("Audio type")
            updateTitle(title: viewModel.getTitle())
            showAudioView(message: message)
        default:
            print("Other type")
        }
    }

    private func updateTitle(title: String) {
        navigationItem.title = title
    }

    private func playVideo() {
        guard let message = viewModel?.getMessageForCurrentIndex(), let filePath = message.filePath,
            let url = viewModel?.getURLFor(name: filePath) else { return }
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        UIViewController.topViewController()?.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }

    private func playAudio() {
        guard let message = viewModel?.getMessageForCurrentIndex(), let filePath = message.filePath,
            let url = viewModel?.getURLFor(name: filePath) else { return }
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        UIViewController.topViewController()?.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }

    @objc private func playButtonAction(_ action: UIButton) {
        playVideo()
    }

    @objc private func audioPlayButtonAction(_ action: UIButton) {
        playAudio()
    }
}

extension ALKMediaViewerViewController: ALKMediaViewerViewModelDelegate {
    func reloadView() {
        guard let message = viewModel?.getMessageForCurrentIndex() else { return }
        updateView(message: message)
    }
}

extension ALKMediaViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let _svSize = self.scrollView.bounds.size
        let _svContentSize = self.scrollView.contentSize
        let offsetX = max( ((_svSize.width - _svContentSize.width) * 0.5) , 0.0)
        let offsetY = max( ((_svSize.height - _svContentSize.height) * 0.5) , 0.0)
        // adjust the center of image view
        self.imageView.center = CGPoint(x: _svContentSize.width * 0.5 + offsetX, y: _svContentSize.height * 0.5 + offsetY)
    }
    
    private func resetScrollImageStatus(imgSize:CGSize){
        self.scrollView.contentOffset = CGPoint.zero
        self.scrollView.setZoomScale(0.0, animated: false)
        //cal zoom size
        let _contentSize = self.scrollView.bounds.size
        let _scaleWidth:CGFloat = (_contentSize.width / imgSize.width)
        let _scaleHeight:CGFloat = (_contentSize.height / imgSize.height)
        var _scale:CGFloat = min(_scaleWidth, _scaleHeight)
        let _scaleUpWidth:CGFloat = (imgSize.width / _contentSize.width)
        let _scaleUpHeight:CGFloat = (imgSize.height / _contentSize.height)
        let _scaleUp:CGFloat = max(_scaleUpWidth, _scaleUpHeight)
        self.scrollView.zoomScale = 0
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = _scaleUp > 2 ? _scaleUp : 2
        //zoom
        if _scale >= 1 {
            _scale = 1.0
        }
        self.imageView.frame = CGRect(x: 0, y: 0, width: imgSize.width * _scale, height: imgSize.height * _scale)
        self.scrollView.contentSize = self.imageView.frame.size
        
        self.scrollViewDidZoom(self.scrollView)
    }
}

fileprivate class CustomActivityIndicatorView : UIActivityIndicatorView, Indicator {
    var view: IndicatorView {
        return self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimatingView() {
        self.startAnimating()
    }
    
    func stopAnimatingView() {
        self.stopAnimating()
    }
}
