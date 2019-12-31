//
//  ALKConversationViewController+CustomCameraProtocol.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 03/07/18.
//

import Foundation
import Applozic

extension ALKConversationViewController: ALKCustomCameraProtocol {

    func customCameraDidTakePicture(cropedImage: UIImage) {
        self.sendMessageWithClearAllModel(completedBlock: {
            print("Image call done")
            self.isJustSent = true
            
            let (message, indexPath) =  self.viewModel.send(photo: cropedImage,metadata : self.configuration.messageMetadata)
            guard let _ = message, let newIndexPath = indexPath else { return }
            self.tableView.beginUpdates()
            self.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
            self.tableView.endUpdates()
            self.tableView.scrollToBottom(animated: false)
            
            guard let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell else { return }
            cell.setLocalizedStringFileName(self.configuration.localizedStringFileName)
            guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                let notificationView = ALNotificationView()
                notificationView.noDataConnectionNotificationView()
                return
            }
            self.viewModel.uploadImage(view: cell, indexPath: newIndexPath)
        })
    }
}
