//
//  FileRetrieval.swift
//  Prey
//
//  Created by Javier Cala Uribe on 1/08/18.
//  Copyright © 2018 Prey Inc. All rights reserved.
//

import Foundation
import Photos

// Prey fileretrieval params
enum kTree: String {
    case name, path, mimetype, size, isFile, hidden
}

class FileRetrieval : PreyAction {
    
    // MARK: Properties

    
    // MARK: Functions    
    
    // Prey command
    override func get() {
        isActive = true
        PreyLogger("Get tree")
        
        // Check iOS version
        guard #available(iOS 9.0, *) else {
            sendEmptyData()
            return
        }

        // Params struct
        var files = [[String:Any]]()
        
        // Create a PHFetchResult object
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        
        for index in 0..<allPhotos.count {
            let resources = PHAssetResource.assetResources(for: allPhotos.object(at: index))
            var sizeOnDisk: Int64 = 1024
            if let resource = resources.first {
                if #available(iOS 10.0, *) {
                    if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                        sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64))
                    }
                }
                files.append([
                    kTree.name.rawValue     : resource.originalFilename,
                    kTree.path.rawValue     : "/" + resource.originalFilename,
                    kTree.mimetype.rawValue : "image/jpeg",
                    kTree.size.rawValue     : sizeOnDisk,
                    kTree.isFile.rawValue   : true,
                    kTree.hidden.rawValue   : false])
            }
        }

        // Check empty path
        guard files.count > 0 else {
            sendEmptyData()
            return
        }
        
        // Send data
        sendTreeDataToPanel(files: files)
    }
    
    func sendEmptyData() {
        var files = [[String:Any]]()
        files.append([
            kTree.name.rawValue     : "Empty",
            kTree.path.rawValue     : "/Empty" ,
            kTree.mimetype.rawValue : "image/jpeg",
            kTree.size.rawValue     : 0,
            kTree.isFile.rawValue   : true,
            kTree.hidden.rawValue   : true])
        
        sendTreeDataToPanel(files: files)
    }
    
    func sendTreeDataToPanel(files:[[String:Any]]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: files,options: .prettyPrinted),
            let jsonString = String(data: jsonData,encoding: String.Encoding.ascii) {
            
            let params:[String: String] = [ kAction.tree.rawValue : jsonString]
            self.sendData(params, toEndpoint: dataDeviceEndpoint)
            
            isActive = false
        }
    }
    
    // Prey command
    override func start() {
        PreyLogger("Start fileretrieval")
        isActive = true
        
        // Send start action
        let params  = getParamsTo(kAction.fileretrieval.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
        
        // Check file_id
        guard let file_id = self.options?.object(forKey: kOptions.file_id.rawValue) as? String else {
            // Send stop action
            PreyLogger("Send stop action on Check file_id")
            self.stopActionFileRetrieval()
            return
        }
        let endpoint = fileRetrievalEndpoint + "?uploadID=" + file_id
        
        // Check name_file
        guard let name_file = self.options?.object(forKey: kOptions.name.rawValue) as? String else {
            // Send stop action
            PreyLogger("Send stop action on Check name_file")
            self.stopActionFileRetrieval()
            return
        }
        
        // Check iOS version
        guard #available(iOS 9.0, *) else {
            // Send stop action
            self.stopActionFileRetrieval()
            return
        }
        
        // Create a PHFetchResult object
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        
        // Search file by name on PHAssets
        for index in 0..<allPhotos.count {
            let resources = PHAssetResource.assetResources(for: allPhotos.object(at: index))
            if let resource = resources.first {
                // Compare names
                guard resource.originalFilename == name_file else {
                    continue
                }
                // Found file
                let manager = PHImageManager.default()
                
                if resource.type == .video {
                    // Upload video
                    let option = PHVideoRequestOptions()
                    option.version = .original
                    manager.requestAVAsset(forVideo: allPhotos.object(at: index), options: option, resultHandler: {(avasset, audiomix, info) in
                        // Check avasset
                        guard let avassetURL = avasset as? AVURLAsset else {
                            // Send stop action
                            self.stopActionFileRetrieval()
                            return
                        }
                        // Check videoData
                        guard let videoData = try? Data(contentsOf: avassetURL.url) else {
                            // Send stop action
                            self.stopActionFileRetrieval()
                            return
                        }
                        // Send file
                        self.sendFileToPanel(data:videoData, endpoint: endpoint)
                    })
                    
                } else {
                    // Upload image
                    let option = PHImageRequestOptions()
                    option.isSynchronous = true
                    manager.requestImageData(for: allPhotos.object(at: index), options: option, resultHandler:{(imageData, string, imageOrientation, info) in
                        // Check imageData
                        guard let data = imageData else {
                            // Send stop action
                            self.stopActionFileRetrieval()
                            return
                        }
                        // Send file
                        self.sendFileToPanel(data:data, endpoint: endpoint)
                    })
                }
                break
            }
        }
    }
    
    func stopActionFileRetrieval() {
        let params  = self.getParamsTo(kAction.fileretrieval.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
        self.isActive = false
    }
    
    func sendFileToPanel(data: Data, endpoint: String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.sendFileToPrey(username, password:"x", file:data, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:endpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:self, onCompletion:{(isSuccess: Bool) in
                PreyLogger("Request fileSend")
                
                // Send stop action
                self.stopActionFileRetrieval()
            }))
        } else {
            PreyLogger("Error send file")
            // Send stop action
            self.stopActionFileRetrieval()
        }
    }
    
}
