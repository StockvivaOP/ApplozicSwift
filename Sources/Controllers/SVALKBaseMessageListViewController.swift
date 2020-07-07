//
//  SVALKBaseMessageListViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 7/7/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit

open class SVALKBaseMessageListViewController: UIViewController {
    
    public var configuration: ALKConfiguration!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    open func refreshTableCell(message: ALKMessageViewModel){
        //for override
    }
}


extension SVALKBaseMessageListViewController {
    //image
    public func openImageViewerPage(viewModel:ALKMessageViewModel?) {
        let storyboard = UIStoryboard.name(
            storyboard: UIStoryboard.Storyboard.mediaViewer,
            bundle: Bundle.applozic)
        guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
        let vc = nav.viewControllers.first as? ALKMediaViewerViewController
        guard let _messageModel = viewModel else { return }
        vc?.delegate = self
        vc?.viewModel = ALKMediaViewerViewModel(
            messages: [_messageModel],
            currentIndex: 0,
            localizedStringFileName: self.configuration.localizedStringFileName)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.present(nav, animated: true, completion: nil)
    }

    //attachment
    public func openAttachmentViewerPage(viewModel: ALKMessageViewModel?) {
        guard  let filePath = viewModel?.filePath, ALKFileUtils().isSupportedFileType(filePath:filePath) else {
            return
        }
        let docViewController = ALKDocumentViewerController()
        docViewController.filePath = viewModel?.filePath ?? ""
        docViewController.fileName = viewModel?.fileMetaInfo?.name ?? ""
        docViewController.message = viewModel
        docViewController.delegate = self
        let _nagVC = UINavigationController(rootViewController: docViewController)
        _nagVC.modalPresentationStyle = .overCurrentContext
        _nagVC.modalTransitionStyle = .crossDissolve
        self.present(_nagVC, animated: true, completion: nil)
    }
}


extension SVALKBaseMessageListViewController : ALKMediaViewerViewControllerDelegate {
    func refreshMediaCell(message: ALKMessageViewModel) {
        self.refreshTableCell(message: message)
    }
}

extension SVALKBaseMessageListViewController : ALKDocumentViewerControllerDelegate {
    func refreshDocumentCell(message: ALKMessageViewModel) {
        self.refreshTableCell(message: message)
    }
}
