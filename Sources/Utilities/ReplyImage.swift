//
//  ReplyImage.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 14/08/19.
//

import UIKit
import Applozic

public struct ReplyMessageImage {

    let videoPlaceholder = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)

    let locationPlaceholder = UIImage(named: "map_no_data", in: Bundle.applozic, compatibleWith: nil)

    let imagePlaceholder = UIImage(named: "photo", in: Bundle.applozic, compatibleWith: nil)

    private func getVideoThumbnail(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    public func previewFor(message: ALKMessageViewModel) -> (URL?, UIImage?) {
        var url: URL? = nil
        switch message.messageType {
        case .photo:
            if let filePath = message.filePath {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                url = docDirPath.appendingPathComponent(filePath)
            } else {
                url = message.thumbnailURL
            }
            return (url, imagePlaceholder)
        case .video:
            var image = videoPlaceholder
            if let filepath = message.filePath {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let path = docDirPath.appendingPathComponent(filepath)
                image = getVideoThumbnail(filePath: path) ?? videoPlaceholder
            }
            return (nil, image)
        case .location:
            guard let lat = message.geocode?.location.latitude,
                let lon = message.geocode?.location.longitude
                else { return (nil, locationPlaceholder) }

            let latLonArgument = String(format: "%f,%f", lat, lon)
            guard let apiKey = ALUserDefaultsHandler.getGoogleMapAPIKey()
                else { return (nil, locationPlaceholder) }
            // swiftlint:disable:next line_length
            let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(latLonArgument)&zoom=17&size=375x295&maptype=roadmap&format=png&visual_refresh=true&markers=\(latLonArgument)&key=\(apiKey)"
            return (URL(string: urlString), locationPlaceholder)
        default:
            return (nil, nil)
        }
    }
    
    public func loadPreviewFor(message: ALKMessageViewModel, completed:@escaping ((URL?, UIImage?)->())) {
        var url: URL? = nil
        switch message.messageType {
        case .photo:
            if let filePath = message.downloadPathURL() {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                url = docDirPath.appendingPathComponent(filePath)
                completed(url, imagePlaceholder)
            } else {
                if let _savedThumbnailURLStr = message.getImageThumbnailURL(),
                    let _savedThumbnailURL = URL(string: _savedThumbnailURLStr) {
                    completed(_savedThumbnailURL, self.imagePlaceholder)
                }else if let _thumbnailURL = message.fileMetaInfo?.thumbnailUrl, let _thumbnailBlobKey = message.fileMetaInfo?.thumbnailBlobKey {
                    ALMessageClientService().downloadImageThumbnailUrl(_thumbnailURL, blobKey: _thumbnailBlobKey) { (url, error) in
                        guard error == nil,
                            let url = url,
                            let _urlObj = URL(string: url)
                            else {
                                print("Error downloading thumbnail url")
                                completed(nil, self.imagePlaceholder)
                                return
                        }
                        completed(_urlObj, self.imagePlaceholder)
                    }
                }else{
                    url = message.thumbnailURL
                    completed(url, self.imagePlaceholder)
                }
            }
            break
        case .video:
            var image = videoPlaceholder
            if let filepath = message.filePath {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let path = docDirPath.appendingPathComponent(filepath)
                image = getVideoThumbnail(filePath: path) ?? videoPlaceholder
            }
            completed(nil, image)
            break
        case .location:
            guard let lat = message.geocode?.location.latitude,
                let lon = message.geocode?.location.longitude else {
                    completed(nil, locationPlaceholder)
                    return
            }
            
            let latLonArgument = String(format: "%f,%f", lat, lon)
            guard let apiKey = ALUserDefaultsHandler.getGoogleMapAPIKey() else {
                completed(nil, locationPlaceholder)
                return
            }
            // swiftlint:disable:next line_length
            let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(latLonArgument)&zoom=17&size=375x295&maptype=roadmap&format=png&visual_refresh=true&markers=\(latLonArgument)&key=\(apiKey)"
            completed(URL(string: urlString), locationPlaceholder)
            break
        default:
            completed(nil, nil)
            break
        }
    }

}
