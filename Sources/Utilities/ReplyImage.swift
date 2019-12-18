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
}
