//
//  ALKCustomPickerConfirmViewController.swift
//  ApplozicSwift
//
//  Created by OldPigChu on 24/9/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKCustomPickerConfirmViewControllerProtocol {
    func didConfirmToSend(images: [UIImage], videos: [String])
}

class ALKCustomPickerConfirmViewController: ALKBaseViewController, Localizable  {

    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    var image: UIImage!
    var images: [UIImage] = []
    var videos: [String] = []
    var delegate:ALKCustomPickerConfirmViewControllerProtocol?
    
    static func instance(images: [UIImage], videos: [String], configuration: ALKConfiguration, delegate:ALKCustomPickerConfirmViewControllerProtocol?) -> ALKCustomPickerConfirmViewController? {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.picker, bundle: Bundle.applozic)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ALKCustomPickerConfirmViewController")
                as? ALKCustomPickerConfirmViewController else { return nil }
        viewController.images = images
        viewController.videos = videos
        viewController.delegate = delegate
        viewController.configuration = configuration
        return viewController
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
    }
    
    override func loadView() {
        super.loadView()
        self.image = self.images[0]
        self.validateEnvironment()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupContent()
        self.title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? localizedString(forKey: "SendPhoto", withDefaultValue: SystemMessage.LabelName.SendPhoto, fileName: configuration.localizedStringFileName)
        UIButton.appearance().tintColor = .white
        self.imageView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.updateMinZoomScaleForSize(size: self.scrollView.bounds.size)
        self.updateConstraintsForSize(size: self.scrollView.bounds.size)
        self.imageView.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Method of class
    private func validateEnvironment() {
        guard let _ = self.image else {
            fatalError("Please use instance(_:) or set image")
        }
    }
    
    private func setupContent() {
        self.imageView.image = self.image
        self.imageView.sizeToFit()
        
        self.scrollView.delegate = self
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(tap:)))
        doubleTap.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func setupNavigation() {
        self.navigationItem.title = title
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.darkGray
        self.navigationController?.navigationBar.tintColor = UIColor.white
        guard let navVC = self.navigationController else {return}
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = false
    }
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    private func updateConstraintsXY(xOffset: CGFloat,yOffset: CGFloat) {
        imageViewTopConstraint?.constant = yOffset
        imageViewBottomConstraint?.constant = yOffset
        
        imageViewLeadingConstraint?.constant = xOffset
        imageViewTrailingConstraint?.constant = xOffset
    }
    
    fileprivate func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        
        self.updateConstraintsXY(xOffset: xOffset, yOffset: yOffset)
    }
    
    @objc private func doubleTapped(tap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: { [weak self, weak imageView] in
            guard let `self` = self else { return }
            guard let `imageView` = imageView else { return }
            
            let view = imageView
            
            let viewFrame = view.frame
            
            let location = tap.location(in: view)
            let viewWidth = viewFrame.size.width/2.0
            let viewHeight = viewFrame.size.height/2.0
            
            let rect = CGRect(
                x: location.x - (viewWidth/2),
                y: location.y - (viewHeight/2),
                width: viewWidth,
                height: viewHeight)
            
            if self.scrollView.minimumZoomScale == self.scrollView.zoomScale {
                self.scrollView.zoom(to: rect, animated: false)
            } else {
                self.updateMinZoomScaleForSize(size: self.scrollView.bounds.size)
            }
            
            }, completion: nil)
    }

    @IBAction private func sendPhotoPress(_ sender: Any) {
        self.delegate?.didConfirmToSend(images: self.images, videos: self.videos)
    }

    @IBAction private func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: false)
    }
}

extension ALKCustomPickerConfirmViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(size: self.scrollView.bounds.size)
        view.layoutIfNeeded()
    }
}