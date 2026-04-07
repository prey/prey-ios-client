//
//  HttpResponse.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case invalidObject
    case notSupported
}

public protocol HttpResponseBodyWriter {
    func write(_ file: String.File) throws
    func write(_ data: [UInt8]) throws
    func write(_ data: ArraySlice<UInt8>) throws
    func write(_ data: NSData) throws
    func write(_ data: Data) throws
}

public enum HttpResponseBody {
    case json(AnyObject)
    case html(String)
    case text(String)
    case data(Data)
    case custom(Any, (Any) throws -> String)

    func content() -> (Int, ((HttpResponseBodyWriter) throws -> Void)?) {
        do {
            switch self {
            case let .json(object):
                #if os(Linux)
                    let data = [UInt8]("Not ready for Linux.".utf8)
                    return (data.count, {
                        try $0.write(data)
                    })
                #else
                    guard JSONSerialization.isValidJSONObject(object) else {
                        throw SerializationError.invalidObject
                    }
                    let data = try JSONSerialization.data(withJSONObject: object)
                    return (data.count, {
                        try $0.write(data)
                    })
                #endif
            case let .text(body):
                let data = [UInt8](body.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            case let .html(body):
                let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
                let data = [UInt8](serialised.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            case let .data(data):
                return (data.count, {
                    try $0.write(data)
                })
            case let .custom(object, closure):
                let serialised = try closure(object)
                let data = [UInt8](serialised.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            }
        } catch {
            let data = [UInt8]("Serialisation error: \(error)".utf8)
            return (data.count, {
                try $0.write(data)
            })
        }
    }
}

// swiftlint:disable cyclomatic_complexity
public enum HttpResponse {
    case switchProtocols([String: String], (Socket) -> Void)
    case ok(HttpResponseBody), created, accepted
    case movedPermanently(String)
    case movedTemporarily(String)
    case badRequest(HttpResponseBody?), unauthorized, forbidden, notFound
    case internalServerError
    case raw(Int, String, [String: String]?, ((HttpResponseBodyWriter) throws -> Void)?)

    func statusCode() -> Int {
        switch self {
        case .switchProtocols: return 101
        case .ok: return 200
        case .created: return 201
        case .accepted: return 202
        case .movedPermanently: return 301
        case .movedTemporarily: return 307
        case .badRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .internalServerError: return 500
        case let .raw(code, _, _, _): return code
        }
    }

    func reasonPhrase() -> String {
        switch self {
        case .switchProtocols: return "Switching Protocols"
        case .ok: return "OK"
        case .created: return "Created"
        case .accepted: return "Accepted"
        case .movedPermanently: return "Moved Permanently"
        case .movedTemporarily: return "Moved Temporarily"
        case .badRequest: return "Bad Request"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not Found"
        case .internalServerError: return "Internal Server Error"
        case let .raw(_, phrase, _, _): return phrase
        }
    }

    func headers() -> [String: String] {
        var headers = ["Server": "Swifter \(HttpServer.VERSION)"]
        switch self {
        case let .switchProtocols(switchHeaders, _):
            for (key, value) in switchHeaders {
                headers[key] = value
            }
        case let .ok(body):
            switch body {
            case .json: headers["Content-Type"] = "application/json"
            case .html: headers["Content-Type"] = "text/html"
            default: break
            }
        case let .movedPermanently(location):
            headers["Location"] = location
        case let .movedTemporarily(location):
            headers["Location"] = location
        case let .raw(_, _, rawHeaders, _):
            if let rawHeaders = rawHeaders {
                for (key, value) in rawHeaders {
                    headers.updateValue(value, forKey: key)
                }
            }
        default: break
        }
        return headers
    }

    func content() -> (length: Int, write: ((HttpResponseBodyWriter) throws -> Void)?) {
        switch self {
        case let .ok(body): return body.content()
        case let .badRequest(body): return body?.content() ?? (-1, nil)
        case let .raw(_, _, _, writer): return (-1, writer)
        default: return (-1, nil)
        }
    }

    func socketSession() -> ((Socket) -> Void)? {
        switch self {
        case let .switchProtocols(_, handler): return handler
        default: return nil
        }
    }
}

/* 
 Makes it possible to compare handler responses with '==', but
 ignores any associated values. This should generally be what
 you want. E.g.:

 let resp = handler(updatedRequest)
 if resp == .NotFound {
 print("Client requested not found: \(request.url)")
 }
 */

func == (inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
    return inLeft.statusCode() == inRight.statusCode()
}
