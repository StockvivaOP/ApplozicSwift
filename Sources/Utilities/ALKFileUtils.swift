//
//  ALKFileUtils.swift
//  ApplozicSwift
//
//  Created by Sunil on 14/03/19.
//

import Foundation
import Applozic
import Photos

open class ALKFileUtils: NSObject {

    public func getFileName(filePath:String?,fileMeta: ALFileMetaInfo?) -> String {
        guard let fileMetaInfo = fileMeta, let fileName = fileMetaInfo.name else {
            guard let localPathName = filePath else {
                return ""
            }
            return  (localPathName as NSString).lastPathComponent as String
        }
        return fileName
    }

    public func getFileSize(filePath: String?,fileMetaInfo:ALFileMetaInfo?) -> String? {

        guard  let fileName = filePath else {
            return fileMetaInfo?.getTheSize()
        }

        let filePath = self.getDocumentDirectory(fileName: fileName).path

        guard  let size = try? FileManager.default.attributesOfItem(atPath:filePath)[FileAttributeKey.size], let fileSize = size as? UInt64
            else {
                return ""
        }
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.1fKB", floatSize)
        }

        floatSize /= 1024
        if floatSize < 1023 {
            return String(format: "%.1fMB", floatSize)
        }

        floatSize /= 1024
        return String(format: "%.1fGB", floatSize)
    }

    public func getFileExtenion(filePath: String?, fileMeta:ALFileMetaInfo?) -> String {
        guard let localPathName = filePath else {
            guard let fileMetaInfo = fileMeta, let name =  fileMetaInfo.name,let pathExtension = URL(string: name)?.pathExtension else {
                return ""
            }
            return pathExtension
        }
        return self.getDocumentDirectory(fileName: localPathName).pathExtension
    }

    func getDocumentDirectory(fileName:String) -> URL {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docDirPath.appendingPathComponent(fileName)
    }

    func isSupportedFileType(filePath: String?) -> Bool {
        guard filePath != nil else {
            return false
        }

        let pathExtension = self.getDocumentDirectory(fileName: filePath ?? "").pathExtension
        let fileTypes = ["docx", "pdf", "doc", "java", "js","txt","html","xlsx","xls","ppt","pptx"]
        return  fileTypes.contains(pathExtension)
    }

    //MARK: - stockviva tag
    func getFileSizeWithMB(url:URL) -> Float{
        let _url:NSURL = url as NSURL
        guard let _filePath = _url.path else {
            return 0
        }
        guard let size = try? FileManager.default.attributesOfItem(atPath:_filePath)[FileAttributeKey.size],
            let fileSize = size as? UInt64 else {
                return 0
        }
        
        let fileSizeKB:Float = Float(fileSize / 1024)
        let fileSizeMB:Float = Float(fileSizeKB / 1024)
        return fileSizeMB
    }
    
    func getFileSizeWithMB(asset:PHAsset) -> Float{
        let _fileResources = PHAssetResource.assetResources(for: asset)
        var sizeOnDisk: Int64? = 0
        if let _resource = _fileResources.first {
            let unsignedInt64 = _resource.value(forKey: "fileSize") as? CLong
            sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
        }
        
        if let _sizeOnDisk = sizeOnDisk, _sizeOnDisk > 0 {
            let _sizeOnDiskStr = "\(_sizeOnDisk)"
            if let _sizeOnDiskFloat = Float(_sizeOnDiskStr) {
                return Float(Int(_sizeOnDiskFloat / Float(1024.0*1024.0)))
            }
        }
        return 0.0
    }
    
    func isImageFile(url:URL) -> Bool{
        var _result = false
        let _fileExtenstion = url.pathExtension as CFString
        if let _uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, _fileExtenstion, nil) {
            _result = UTTypeConformsTo((_uti as! CFString), kUTTypeImage)
        }
        return _result
    }
}
