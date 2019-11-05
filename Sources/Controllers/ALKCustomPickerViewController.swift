//
//  CustomPickerView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 14/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Photos

protocol ALKCustomPickerDelegate: class {
    func filesSelected(images: [UIImage], videos: [String])
}

class ALKCustomPickerViewController: ALKBaseViewController, Localizable {
    //photo library
    var asset: PHAsset!
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedImage:UIImage!
    var cameraMode:ALKCameraPhotoType = .noCropOption
    let option = PHImageRequestOptions()
    var selectedRows = [Int]()
    var selectedFiles = [IndexPath]()
    var isAllowShowVideo:Bool = true
    var allowsMultipleSelection:Bool = false
    var conversationRequestInfoDelegate:ConversationCellRequestInfoDelegate?
    
    //private
    private var isTabbarHidden:Bool = false

    @IBOutlet weak var doneButton: UIBarButtonItem!
    weak var delegate: ALKCustomPickerDelegate?

    @IBOutlet weak var previewGallery: UICollectionView!

    private lazy var localizedStringFileName: String = configuration.localizedStringFileName

    fileprivate let indicatorSize = ALKActivityIndicator.Size(width: 50, height: 50)
    fileprivate lazy var activityIndicator = ALKActivityIndicator(frame: .zero, backgroundColor: .lightGray, indicatorColor: .white, size: indicatorSize)

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "general_button_confirm") ?? localizedString(forKey: "DoneButton", withDefaultValue: SystemMessage.ButtonName.Done, fileName: localizedStringFileName)
        self.title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? localizedString(forKey: "PhotosTitle", withDefaultValue: SystemMessage.LabelName.Photos, fileName: localizedStringFileName)
        checkPhotoLibraryPermission()
        previewGallery.delegate = self
        previewGallery.dataSource = self
        previewGallery.allowsMultipleSelection = self.allowsMultipleSelection

        view.addViewsForAutolayout(views: [activityIndicator])
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: indicatorSize.width).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: indicatorSize.height).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        self.isTabbarHidden = self.tabBarController?.tabBar.isHidden ?? false
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = self.isTabbarHidden
    }

    static func makeInstanceWith(delegate: ALKCustomPickerDelegate, conversationRequestInfoDelegate:ConversationCellRequestInfoDelegate?, and configuration: ALKConfiguration) -> ALKBaseNavigationViewController? {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.picker, bundle: Bundle.applozic)
        guard
            let vc = storyboard.instantiateViewController(withIdentifier: "CustomPickerNavigationViewController")
                as? ALKBaseNavigationViewController,
            let cameraVC = vc.viewControllers.first as? ALKCustomPickerViewController else { return nil }
        cameraVC.delegate = delegate
        cameraVC.configuration = configuration
        cameraVC.isAllowShowVideo = configuration.isShowVideoFile
        cameraVC.allowsMultipleSelection = configuration.isAllowsMultipleSelection
        cameraVC.conversationRequestInfoDelegate = conversationRequestInfoDelegate
        return vc
    }

    // MARK: - UI control
    private func setupNavigation() {
        self.navigationController?.title = title
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        guard let navVC = self.navigationController else {return}
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
        var backImage = UIImage.init(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
        backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: backImage, style: .plain, target: self , action: #selector(dismissAction(_:)))
        self.navigationController?.navigationBar.tintColor = UIColor.white

    }

    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.getAllImage(completion: { [weak self] (isGrant) in
                guard let weakSelf = self else {return}
                weakSelf.createScrollGallery(isGrant:isGrant)
            })
            break
        //handle authorized status
        case .denied, .restricted :
            break
        //handle denied status
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.getAllImage(completion: {[weak self] (isGrant) in
                        guard let weakSelf = self else {return}
                        weakSelf.createScrollGallery(isGrant:isGrant)
                    })
                    break
                // as above
                case .denied, .restricted:
                    break
                default: break
                    //whatever
                }
            }
        }
    }

    // MARK: - Access to gallery images
    private func getAllImage(completion: (_ success: Bool) -> Void) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false

        let p1 = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        if self.isAllowShowVideo {
            let p2 = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            allPhotosOptions.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2])
        }else{
            allPhotosOptions.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [p1])
        }
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        (allPhotos != nil) ? completion(true) :  completion(false)
    }

    private func createScrollGallery(isGrant:Bool) {
        if isGrant {
            self.selectedRows = Array(repeating: 0, count: (self.allPhotos != nil) ? self.allPhotos.count:0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.previewGallery.reloadData()
            })
        }

    }

    func exportVideoAsset(_ asset: PHAsset, _ completion: @escaping ((_ video: String?) -> Void)) {
        let filename = String(format: "VID-%f.mp4", Date().timeIntervalSince1970*1000)
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        var fileurl = URL(fileURLWithPath: documentsUrl.absoluteString).appendingPathComponent(filename)
        print("exporting video to ", fileurl)
        fileurl = fileurl.standardizedFileURL

        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        // remove any existing file at that location
        do {
            try FileManager.default.removeItem(at: fileurl)
        } catch {
            // most likely, the file didn't exist.  Don't sweat it
        }

        PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) {
            (exportSession: AVAssetExportSession?, _) in

            if exportSession == nil {
                print("COULD NOT CREATE EXPORT SESSION")
                completion(nil)
                return
            }

            exportSession!.outputURL = fileurl
            exportSession!.outputFileType = AVFileType.mp4 //file type encode goes here, you can change it for other types

            exportSession!.exportAsynchronously() {
                switch exportSession!.status {
                case .completed:
                    print("Video exported successfully")
                    completion(fileurl.path)
                case .failed, .cancelled:
                    print("Error while selecting video \(String(describing: exportSession?.error))")
                    completion(nil)
                default:
                    print("Video exporting status \(String(describing: exportSession?.status))")
                    completion(nil)
                    break
                }
            }
        }
    }

    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        activityIndicator.startAnimating()
        export { (images, videos, error, isShowAlert) in
            self.activityIndicator.stopAnimating()
            if error {
                if isShowAlert == false {
                    return
                }
                let alertTitle = self.localizedString(
                    forKey: "PhotoAlbumFailureTitle",
                    withDefaultValue: SystemMessage.PhotoAlbum.FailureTitle,
                    fileName: self.localizedStringFileName)
                let alertMessage = self.localizedString(
                    forKey: "VideoExportError",
                    withDefaultValue: SystemMessage.Warning.videoExportError,
                    fileName: self.localizedStringFileName)
                let buttonTitle = self.localizedString(
                    forKey: "OkMessage",
                    withDefaultValue: SystemMessage.ButtonName.ok,
                    fileName: self.localizedStringFileName)
                let alert = UIAlertController(
                    title: alertTitle,
                    message: alertMessage,
                    preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default, handler: { _ in
                    //self.goToPickerConfirmatPage(images: images, videos: videos)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.goToPickerConfirmatPage(images: images, videos: videos)
            }
        }

    }

    func export(_ completion: @escaping ((_ images: [UIImage], _ videos: [String], _ error: Bool, _ isShowAlert:Bool) -> Void)) {
        var selectedImages = [UIImage]()
        var selectedVideos = [String]()
        var error: Bool = false
        let group = DispatchGroup()
        DispatchQueue.global(qos: .background).async {
            for indexPath in self.selectedFiles {
                group.wait()
                group.enter()
                let asset = self.allPhotos.object(at: indexPath.item)
                
                if self.isOverUploadFileLimit(asset: asset) {
                    group.leave()
                    DispatchQueue.main.async {
                        self.conversationRequestInfoDelegate?.requestToShowAlert(type:.attachmentFileSizeOverLimit)
                        completion([], [], true, false)
                    }
                    return
                }
                
                if asset.mediaType == .video {
                    self.exportVideoAsset(asset) { (video) in
                        guard let video = video else {
                            error = true
                            group.leave()
                            return
                        }
                        selectedVideos.append(video)
                        group.leave()
                    }
                } else {
                    let options = PHImageRequestOptions()
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    options.isSynchronous = false
                    options.isNetworkAccessAllowed = true
                    PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options, resultHandler: { (imageRespon, info) in
                        guard let image = imageRespon else {
                            error = true
                            group.leave()
                            return
                        }
                        selectedImages.append(image)
                        group.leave()
                    })
                }
            }
            group.wait()
            DispatchQueue.main.async {
                completion(selectedImages, selectedVideos, error, true)
            }
        }
    }

    @IBAction func dismissAction(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: false, completion: nil)
    }
    
    private func goToPickerConfirmatPage(images: [UIImage], videos: [String]){
        var _goToConfirm = false
        if images.count > 0 {
            if let _vc = ALKCustomPickerConfirmViewController.instance(images: images, videos: videos, configuration: configuration, delegate: self) {
                _goToConfirm = true
                self.navigationController?.pushViewController(_vc, animated: true)
            }
        }
        if _goToConfirm == false {
            self.didConfirmToSend(images: images, videos: videos)
        }
    }
    
    private func isOverUploadFileLimit(asset:PHAsset) -> Bool{
        var _result = false
        let _fileSize = ALKFileUtils().getFileSizeWithMB(asset: asset)
        if _fileSize > self.configuration.maxUploadFileMBSize {
            _result = true
        }
        return _result
    }
}

extension ALKCustomPickerViewController: ALKCustomPickerConfirmViewControllerProtocol {
    func didConfirmToSend(images: [UIImage], videos: [String]) {
        self.delegate?.filesSelected(images: images, videos: videos)
        self.navigationController?.dismiss(animated: false, completion: nil)
    }
}

extension ALKCustomPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: CollectionViewEnvironment
    private class CollectionViewEnvironment {
        struct Spacing {
            static let lineitem: CGFloat = 5.0
            static let interitem: CGFloat = 0.0
            static let inset: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 3.0, bottom: 0.0, right: 3.0)
        }
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //grab all the images
        //let asset = allPhotos.object(at: indexPath.item)
        //for single select
        if self.allowsMultipleSelection == false {
            //un-select all
            var _isDeselectMode = false
            var _refreshCell = [IndexPath]()
            _refreshCell.append(contentsOf: selectedFiles)
            for sIndex in selectedFiles {
                if sIndex.row == indexPath.row {
                    _isDeselectMode = true
                }
                selectedRows[sIndex.row] = 0
            }
            selectedFiles.removeAll()
            if _isDeselectMode == false {// not deselect mode
                selectedFiles.append(indexPath)
                _refreshCell.append(indexPath)
                selectedRows[indexPath.row] = 1
            }
            //refresh cell
            previewGallery.reloadItems(at: _refreshCell)
        }else {
            if selectedRows[indexPath.row] == 1 {
                selectedFiles.remove(object: indexPath)
                selectedRows[indexPath.row] = 0
            } else {
                selectedFiles.append(indexPath)
                selectedRows[indexPath.row] = 1
            }
            previewGallery.reloadItems(at: [indexPath])
        }
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(allPhotos == nil) {
            return 0
        } else {
            return allPhotos.count
        }

    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKPhotoCollectionCell", for: indexPath) as! ALKPhotoCollectionCell

//        cell.selectedIcon.isHidden = true
        cell.videoIcon.isHidden = true
        cell.selectedIcon.isHidden = true
        if selectedRows[indexPath.row] == 1 {
            cell.selectedIcon.isHidden = false
        }

        let asset = allPhotos.object(at: indexPath.item)
        if asset.mediaType == .video {
            cell.videoIcon.isHidden = false
        }
        let thumbnailSize:CGSize = CGSize(width: 200, height: 200)
        option.isSynchronous = true
        PHCachingImageManager.default().requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: option, resultHandler: { image, _ in
            cell.imgPreview.image = image
        })

        cell.imgPreview.backgroundColor = UIColor.white

        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CollectionViewEnvironment.Spacing.lineitem
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CollectionViewEnvironment.Spacing.interitem
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return CollectionViewEnvironment.Spacing.inset
    }
}
