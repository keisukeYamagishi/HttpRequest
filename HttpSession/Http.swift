//
//  HttpRequest.swift
//  swiftDemo
//
//  Created by shichimi on 2017/03/11.
//  Copyright © 2017年 shichimitoucarashi. All rights reserved.
//

import Foundation
import UIKit

let VERSION = "1.3.4"
// swiftlint:disable all
public protocol HttpApi: AnyObject {

    associatedtype ApiType: ApiProtocol

    func request(api: ApiType, completion:@escaping(Data?, HTTPURLResponse?, Error?) -> Void)

    func download (api: ApiType,
                   data: Data?,
                   progress: @escaping (_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void,
                   download: @escaping (_ path: URL?) -> Void,
                   completionHandler: @escaping(Data?, HTTPURLResponse?, Error?) -> Void)
}

open class ApiProvider<Type: ApiProtocol>: HttpApi {

    public typealias ApiType = Type
    public var http: Http?

    public init(){}

    public func request(api: Type, completion:@escaping(Data?, HTTPURLResponse?, Error?) -> Void) {
        if self.http == nil {
            self.http = Http(api: api)
        }
        http!.session(completion: completion)
    }

    public func download(api: Type,
                         data: Data? = nil,
                         progress: @escaping (Int64, Int64, Int64) -> Void,
                         download: @escaping (URL?) -> Void,
                         completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        if self.http == nil {
            self.http = Http(api: api)
        }
        self.http!.download(resumeData: data,
                            progress: progress,
                            download: download,
                            completionHandler: completionHandler)
    }
}

open class Http: NSObject {

    /*
     * Http method
     */
    public enum Method: String {
        case get  = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
    }

    /*
     * member's value
     *
     */
    public var data: Data = Data()
    public var params: [String: String]?
    public var response: HTTPURLResponse?
    public var dataTask: URLSessionDataTask!
    public var downloadTask: URLSessionDownloadTask!
    public var url: String?
    public var sessionConfig: URLSessionConfiguration?
    public var session: URLSession?
    public var request: Request?

    public var isCookie: Bool = false

    public init(url: String,
                method: Method = .get,
                header: [String: String]? = nil,
                params: [String: String] = [:],
                cookie: Bool = false,
                basic: [String: String]? = nil) {

        self.isCookie = cookie
        self.params = params
        self.request = Request(url: url,
                               method: method,
                               headers: header,
                               parameter: params,
                               cookie: cookie,
                               basic: basic)
    }

    public convenience init(api: ApiProtocol) {

        let url = api.domain + "/" + api.endPoint

        self.init(url: url,
                  method: api.method,
                  header: api.header,
                  params: api.params,
                  cookie: api.isCookie,
                  basic: api.basicAuth)
    }

    /*
     * Callback function
     * success Handler
     *
     */
    public typealias CompletionHandler = (Data?, HTTPURLResponse?, Error?) -> Void
    public typealias ProgressHandler = (_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void
    public typealias DownloadHandler = (_ path: URL?) -> Void

    public var progress: ProgressHandler?
    public var completion: CompletionHandler?
    public var download: DownloadHandler?

    public func session(completion: @escaping(Data?, HTTPURLResponse?, Error?) -> Void) {
        self.completion = completion
        self.send(request: (self.request?.urlReq)!)
    }

    public func download (resumeData: Data? = nil,
                          progress: @escaping (_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void,
                          download: @escaping (_ path: URL?) -> Void,
                          completionHandler: @escaping(Data?, HTTPURLResponse?, Error?) -> Void) {

        if resumeData == nil {
            self.progress = progress
            self.completion = completionHandler
            self.download = download
            self.sessionConfig = URLSessionConfiguration.background(withIdentifier: "httpSession-background")
            self.session = URLSession(configuration: sessionConfig!, delegate: self, delegateQueue: .main)

            self.downloadTask = self.session!.downloadTask(with: (self.request?.urlReq)!)
        } else {
            self.downloadTask = self.session?.downloadTask(withResumeData: resumeData!)
        }
        self.downloadTask.resume()
    }

    public func cancel (byResumeData: @escaping(Data?) -> Void) {
        self.downloadTask.cancel { (data) in
            byResumeData(data)
        }
    }

    public func upload(param: [String: MultipartDto],
                       completionHandler: @escaping(Data?, HTTPURLResponse?, Error?) -> Void) {
        self.completion = completionHandler
        self.send(request: (self.request?.multipart(param: param))!)
    }

    /*
     * send Request
     */
    func send(request: URLRequest) {
        if self.sessionConfig == nil {
            self.sessionConfig = URLSessionConfiguration.default
        }
        let session = URLSession(configuration: self.sessionConfig!, delegate: self, delegateQueue: .main)
        self.dataTask = session.dataTask(with: request)
        self.dataTask.resume()
    }
}

extension Http: URLSessionDataDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        self.download?(location)
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        self.progress!(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    /*
     * Get Responce and Result
     *
     *
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if self.isCookie == true {
            self.isCookie = false
            Cookie.shared.set(responce: response!)
        }
        self.completion?(self.data, self.response, error)
    }

    /*
     * get recive function
     *
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        self.data.append(data)

        guard !data.isEmpty else { return }
    }

    /*
     * get Http response
     *
     */
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        completionHandler(.allow)
    }
}
// swiftlint:enable all