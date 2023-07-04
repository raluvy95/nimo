import std/times
import strformat

# HTTP/1.1 200 OK
# Date: Mon, 27 Jul 2009 12:28:53 GMT
# Server: Apache/2.2.14 (Win32)
# Last-Modified: Wed, 22 Jul 2009 19:15:56 GMT
# Content-Length: 88
# Content-Type: text/html
# Connection: Closed

proc parseHTTPStatus(status: int): string =
    case status
    of 100:
        return "Continue"
    of 200:
        return "OK"
    of 201:
        return "Created"
    of 202:
        return "Accepted"
    of 300:
        return "Multiple Choices"
    of 301:
        return "Moved Permanently"
    of 302:
        return "Found"
    of 400:
        return "Bad Request"
    of 401:
        return "Unauthorized"
    of 402:
        return "Payment Required"
    of 403:
        return "Forbidden"
    of 404:
        return "Not Found"
    of 500:
        return "Internal Server Error"
    of 501:
        return "Not Implemented"
    of 502:
        return "Bad Gateway"
    else:
        return "Unknown"

proc responseHTTPHeader*(status: int, contentType: string,
        content: string): string =
    fmt"""HTTP/1.1 {status} {parseHTTPStatus(status)}
Date: {now().utc.format("ddd, dd MMM YYYY HH:mm:ss")} (GMT)
Server: Nimo/0.0.0
Content-Type: {contentType}
Connection: close

""" & content
