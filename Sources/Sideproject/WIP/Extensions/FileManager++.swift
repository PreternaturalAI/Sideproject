//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation

extension FileManager {
    func directorySize(url: URL) -> Int64 {
        let contents: [URL]
        do {
            contents = try self.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
        } catch {
            return 0
        }
        
        var size: Int64 = 0
        
        for url in contents {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            
            if isDirectoryResourceValue.isDirectory == true {
                size += directorySize(url: url)
            } else {
                let fileSizeResourceValue: URLResourceValues
                do {
                    fileSizeResourceValue = try url.resourceValues(forKeys: [.fileSizeKey])
                } catch {
                    continue
                }
                
                size += Int64(fileSizeResourceValue.fileSize ?? 0)
            }
        }
        return size
    }

}
