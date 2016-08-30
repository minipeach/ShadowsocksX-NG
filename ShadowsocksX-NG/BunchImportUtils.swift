//
//  BunchImportUtils.swift
//  ShadowsocksX-NG
//
//  Created by 秦宇航 on 16/8/26.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

var profileMgr: ServerProfileManager!

//Todo: function 1 showExampleFile, 调用fileManager 拷贝 json 到Downloads文件夹，然后打开Downloads文件夹

//拷贝json配置文件到~/Downloads文件夹
func showExampleConfigFile() {
    //copy file to ~/Downloads folder
    let filePath:String = Bundle.main.bundlePath + "/Contents/Resources/example-gui-config.json"
    let fileMgr = FileManager.default
    let dataPath = NSHomeDirectory() + "/Downloads"
    let destPath = dataPath + "/example-gui-config.json"
    //检测文件是否已经存在，如果存在直接用sharedWorkspace显示
    if fileMgr.fileExists(atPath: destPath) {
        NSWorkspace.shared().selectFile(destPath, inFileViewerRootedAtPath: dataPath)
    }else{
        try! fileMgr.copyItem(atPath: filePath, toPath: destPath)
        NSWorkspace.shared().selectFile(destPath, inFileViewerRootedAtPath: dataPath)
    }
}

//调用fileManager，读取json文件，对configs for循环调用 profileManager 生成 profile并保存
func importConfigFile() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Choose Config Json File".localized
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.canChooseFiles = true
    openPanel.begin { (result) -> Void in
        if (result == NSFileHandlingPanelOKButton && (openPanel.url) != nil) {
            let fileManager = FileManager.default
            let filePath:String = (openPanel.url?.path)!
            if (fileManager.fileExists(atPath: filePath) && filePath.hasSuffix("json")) {
                let data = fileManager.contents(atPath: filePath)
                let readString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                let readStringData = readString.data(using: String.Encoding.utf8.rawValue)

                let jsonArr1 = try! JSONSerialization.jsonObject(with: readStringData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                
                for item in jsonArr1.object(forKey: "configs") as! [[String: AnyObject]]{
                    let profile = ServerProfile()
                    var profileMgr: ServerProfileManager!
                    profileMgr = ServerProfileManager.instance
                    profile.serverHost = item["server"] as! String
                    profile.serverPort = UInt16((item["server_port"]?.int16Value)!)
                    profile.method = item["method"] as! String
                    profile.password = item["password"] as! String
                    profile.remark = item["remarks"] as! String
                    if (item["obfs"] != nil) {
                        profile.ssrObfs = item["obfs"] as! String
                        profile.ssrProtocol = item["protocol"] as! String
                        if (item["obfsparam"] != nil){
                            profile.ssrObfsParam = item["obfsparam"] as! String
                        }
                        if (item["protocolparam"] != nil){
                            profile.ssrProtocolParam = item["protocolparam"] as! String
                        }
                    }
                    profileMgr.profiles.append(profile)
                    profileMgr.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFY_SERVER_PROFILES_CHANGED), object: nil)
                }
                let configsCount = (jsonArr1.object(forKey: "configs") as AnyObject).count
                let notification = NSUserNotification()
                notification.title = "Import Server Profile succeed!".localized
                notification.informativeText = "Successful import \(configsCount) items".localized
                NSUserNotificationCenter.default
                    .deliver(notification)
            }else{
                let notification = NSUserNotification()
                notification.title = "Import Server Profile failed!".localized
                notification.informativeText = "Invalid config file!".localized
                NSUserNotificationCenter.default
                    .deliver(notification)
                return
            }
        }
    }
}

func exportConfigFile() {
    //读取example文件，删掉configs里面的配置，再用NSDictionary填充到configs里面
    profileMgr = ServerProfileManager.instance
    let fileManager = FileManager.default
    
    let filePath:String = Bundle.main.bundlePath + "/Contents/Resources/example-gui-config.json"
    let data = fileManager.contents(atPath: filePath)
    let readString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
    let readStringData = readString.data(using: String.Encoding.utf8.rawValue)
    let jsonArr1 = try! JSONSerialization.jsonObject(with: readStringData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
    
    let configsArray:NSMutableArray = [] //not using var?
    
    for profile in profileMgr.profiles{
        let configProfile:NSMutableDictionary = [:] //not using var?
        //standard ss profile
        configProfile.setValue(true, forKey: "enable")
        configProfile.setValue(profile.serverHost, forKey: "server")
        configProfile.setValue(NSNumber(value:profile.serverPort), forKey: "server_port")//not work
        configProfile.setValue(profile.password, forKey: "password")
        configProfile.setValue(profile.method, forKey: "method")
        configProfile.setValue(profile.remark, forKey: "remarks")
        configProfile.setValue(profile.remark.data(using: String.Encoding.utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)), forKey: "remarks_base64")
        //ssr
        if  1 == 1 {
            configProfile.setValue(profile.ssrObfs, forKey: "obfs")
            configProfile.setValue(profile.ssrProtocol, forKey: "protocol")
            if 2 == 2 {
                configProfile.setValue(profile.ssrObfsParam, forKey: "obfsparam")
            }
            if 3 == 3 {
                configProfile.setValue(profile.ssrProtocolParam, forKey: "protoclparam")
            }
        }
        configsArray.add(configProfile)
    }
    jsonArr1.setValue(configsArray, forKey: "configs")
    let jsonData = try! JSONSerialization.data(withJSONObject: jsonArr1, options: JSONSerialization.WritingOptions.prettyPrinted)
    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
    let savePanel = NSSavePanel()
    savePanel.title = "Export Config Json File".localized
    savePanel.canCreateDirectories = true
    savePanel.allowedFileTypes = ["json"]
    savePanel.nameFieldStringValue = "export.json"
    savePanel.begin { (result) -> Void in
        if (result == NSFileHandlingPanelOKButton && (savePanel.url) != nil) {
            //write jsonArr1 back to file
            try! jsonString.write(toFile: (savePanel.url?.path)!, atomically: true, encoding: String.Encoding.utf8)
            NSWorkspace.shared().selectFile((savePanel.url?.path)!, inFileViewerRootedAtPath: (savePanel.directoryURL?.path)!)
        }
    }
}
