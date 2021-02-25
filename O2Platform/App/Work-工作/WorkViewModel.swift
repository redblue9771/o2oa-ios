//
//  WorkViewModel.swift
//  O2Platform
//
//  Created by FancyLou on 2021/2/24.
//  Copyright © 2021 zoneland. All rights reserved.
//
import Promises
import CocoaLumberjack


class WorkViewModel : NSObject {
    override init() {
        super.init()
    }
    
    private let api = OOMoyaProvider<OOApplicationAPI>()
}

extension WorkViewModel {
    
    /// 删除工作
    func deleteWork(workId: String) -> Promise<Bool> {
        return Promise{ fulfill, reject in
            self.api.request(.workDelete(workId), completion: { result in
                let response = OOResult<BaseModelClass<OOCommonIdModel>>(result)
                if response.isResultSuccess() {
                    fulfill(true)
                } else {
                    reject(response.error!)
                }
            })
        }
    }
    
    /// 保存工作
    func saveWorkData(workId: String, data: [String: AnyObject]) -> Promise<Bool> {
        return Promise{ fulfill, reject in
            self.api.request(.dataUpdateWithWork(workId, data), completion: { result in
                let response = OOResult<BaseModelClass<OOCommonIdModel>>(result)
                if response.isResultSuccess() {
                    fulfill(true)
                } else {
                    reject(response.error!)
                }
            })
        }
    }
    
    /// 上传附件
    func uploadAttachment(workId: String, site: String, fileName:String, fileData: Data) -> Promise<OOCommonIdModel> {
        return Promise { fulfill, reject in
            self.api.request(.attachmentUpload(workId, site, fileName, fileData), completion: { result in
                let response = OOResult<BaseModelClass<OOCommonIdModel>>(result)
                if response.isResultSuccess() {
                    if let idData = response.model?.data {
                        fulfill(idData)
                    }else {
                        reject(OOAppError.apiEmptyResultError)
                    }
                } else {
                    reject(response.error!)
                }
            })
        }
    }
    
    /// 替换附件
    func replaceAttachment(id: String, workId: String, site: String, fileName: String, fileData: Data)  -> Promise<OOCommonIdModel> {
        return Promise { fulfill, reject in
            self.api.request(.attachmentReplace(id, workId, site, fileName, fileData), completion: { result in
                let response = OOResult<BaseModelClass<OOCommonIdModel>>(result)
                if response.isResultSuccess() {
                    if let idData = response.model?.data {
                        fulfill(idData)
                    }else {
                        reject(OOAppError.apiEmptyResultError)
                    }
                } else {
                    reject(response.error!)
                }
            })
        }
    }
    
    /// work的附件
    func getWorkAttachment(workId: String, id: String) -> Promise<String> {
        return Promise { fulfill, reject in
            self.getAttachmentWithworkOrWorkcompleted(workOrWorkcompleted: workId, id: id).then { (info) -> Promise<URL> in
                return self.downloadAttachmentWithWorkId(id: id, workId: workId, info: info)
            }.then { (url)  in
                fulfill(url.path)
            }.catch { (err) in
                reject(err)
            }
        }
    }
    
    /// workcompleted的附件
    func getWorkcompletedAttachment(workcompleted: String, id: String) -> Promise<String> {
        return Promise { fulfill, reject in
            self.getAttachmentWithworkOrWorkcompleted(workOrWorkcompleted: workcompleted, id: id).then { (info) -> Promise<URL> in
                return self.downloadAttachmentWithWorkcompleted(id: id, workcompleted: workcompleted, info: info)
            }.then { (url)  in
                fulfill(url.path)
            }.catch { (err) in
                reject(err)
            }
        }
    }
    
    /// 获取附件对象
    func getAttachmentWithworkOrWorkcompleted(workOrWorkcompleted: String, id: String) -> Promise<O2WorkAttachmentInfo> {
        return Promise { fulfill, reject in
            self.api.request(.attachmentGetWithWorkOrWorkCompleted(workOrWorkcompleted, id), completion: { result in
                let response = OOResult<BaseModelClass<O2WorkAttachmentInfo>>(result)
                if response.isResultSuccess() {
                    if let atta = response.model?.data {
                        fulfill(atta)
                    }else {
                        reject(OOAppError.apiEmptyResultError)
                    }
                } else {
                    reject(response.error!)
                }
            })
        }
    }
    
    /// 下载附件
    private func downloadAttachmentWithWorkId(id: String, workId: String, info: O2WorkAttachmentInfo) -> Promise<URL> {
        let path = FileUtil.share.cacheDir().appendingPathComponent("\(info.name ?? "temp").\(info.extension ?? "")")
        DDLogDebug("file Path: \(path)")
        if FileUtil.share.fileExist(filePath: path.path) {
            if let updateTime = info.updateTime,  let updateDate = Date.date(updateTime), let fileDate = FileUtil.share.fileModificationDate(filePath: path.path) as Date? {
                DDLogDebug("file updateDate: \(updateDate) fileDate: \(fileDate)")
                if updateDate > (fileDate) { // 重新下载
                    return Promise { fulfill, reject in
                        self.api.request(.attachmentDownloadWithWorkId(id, workId, path), completion: { result in
                            switch result {
                                case .success(_):
                                    DDLogError("重新下载成功。。。。。")
                                    fulfill(path)
                                    break
                                case .failure(let err):
                                    DDLogError(err.localizedDescription)
                                    reject(err)
                                    break
                                }
                        })
                    }
                }
            }
            
            return Promise { fulfill, reject in
                fulfill(path)
            }
        }else {
            return Promise { fulfill, reject in
                self.api.request(.attachmentDownloadWithWorkId(id, workId, path), completion: { result in
                    switch result {
                        case .success(_):
                            DDLogError("下载成功。。。。。")
                            fulfill(path)
                            break
                        case .failure(let err):
                            DDLogError(err.localizedDescription)
                            reject(err)
                            break
                        }
                })
            }
        }
    }
    
    /// 下载附件
    private func downloadAttachmentWithWorkcompleted(id: String, workcompleted: String, info: O2WorkAttachmentInfo) -> Promise<URL> {
        let path = FileUtil.share.cacheDir().appendingPathComponent("\(info.name ?? "temp").\(info.extension ?? "")")
        DDLogDebug("file Path: \(path)")
        if FileUtil.share.fileExist(filePath: path.path) {
            if let updateTime = info.updateTime,  let updateDate = Date.date(updateTime), let fileDate = FileUtil.share.fileModificationDate(filePath: path.path) as Date? {
                DDLogDebug("file updateDate: \(updateDate) fileDate: \(fileDate)")
                if updateDate > (fileDate) { // 重新下载
                    return Promise { fulfill, reject in
                        self.api.request(.attachmentDownloadWithWorkCompleted(id, workcompleted, path), completion: { result in
                            switch result {
                                case .success(_):
                                    DDLogError("重新下载成功。。。。。")
                                    fulfill(path)
                                    break
                                case .failure(let err):
                                    DDLogError(err.localizedDescription)
                                    reject(err)
                                    break
                                }
                        })
                    }
                }
            }
            return Promise { fulfill, reject in
                fulfill(path)
            }
        }else {
            return Promise { fulfill, reject in
                self.api.request(.attachmentDownloadWithWorkCompleted(id, workcompleted, path), completion: { result in
                    switch result {
                        case .success(_):
                            DDLogError("下载成功。。。。。")
                            fulfill(path)
                            break
                        case .failure(let err):
                            DDLogError(err.localizedDescription)
                            reject(err)
                            break
                        }
                })
            }
        }
    }
}
