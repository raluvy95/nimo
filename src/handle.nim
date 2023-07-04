import strutils
import header
import std/[uri, times, mimetypes, sequtils]
import net
import strformat
import debug
import parser
import os

type handleHTTPEventResponse = ref object
    response: string
    contentType: string
    code: int

proc getMime(fileName: string): string =
    # implictly index.html
    let ext_r = fileName.split('.')
    let ext = ext_r[ext_r.high]
    if ext.len == 0:
        return "text/html"
    else:
        return getMimeType(newMimetypes(), ext, "text/plain")

type HTTPRequest = ref object
    METHOD: string
    PATH: Uri
    HTTP: string

proc getHTTPRequest(input: string): HTTPRequest =
    var r: HTTPRequest = HTTPRequest()

    var http_headers = input.splitLines()

    let http = http_headers[0]
    http_headers.delete(0)

    proc findHost(x: string): bool =
        x.toLower().startsWith("host:")
    let http_host_r = http_headers.filter(findHost)
    if http_host_r.len < 0:
        raise newException(ValueError, "No Host found")
    let http_host = http_host_r[0].split(":")[1].strip()
    let http_request = http.split(" ")
    case http_request[0].toLower()
    of "get":
        discard
    else:
        raise newException(ValueError, "not implemented yet")

    r.METHOD = http_request[0]
    r.PATH = parseUri(fmt"http://{http_host}{http_request[1]}")
    r.HTTP = http_request[2]
    return r



proc handleHTTPEvent(string_buffer: string): handleHTTPEventResponse =
    var r: handleHTTPEventResponse = handleHTTPEventResponse()

    var request: HTTPRequest = getHTTPRequest(string_buffer)
    var pathes = request.PATH.path.split("/")
    var file: string
    try:
        file = pathes[pathes.high]
        pathes.delete(pathes.high)
    except IndexDefect:
        file = ""
    if file.len() == 0:
        file = "index.html"

    let arg: ArgParser = getParse()
    debug fmt"""The file is {file} on path {arg.directory}{pathes.join("/")}"""
    try:
        let path: string = joinPath(arg.directory & pathes.join("/"), file)
        debug path
        r.response = readFile(path)
        debug "Response size is " & formatSize(r.response.len)
        r.contentType = getMime(file)
        r.code = 200
    except CatchableError:
        r.response = "Not found"
        r.contentType = "text/plain"
        r.code = 404
    return r

proc handleClient*(client: Socket): void {.thread.} =
    var time_before_processing = cpuTime()

    var string_received: string = ""
    let status = client.recv(string_received, 128)
    if status < 0:
        debug fmt"receiver returned {status}"
    elif status > 0:
        try:
            let content: handleHTTPEventResponse = handleHTTPEvent(string_received)
            let response: string = responseHTTPHeader(content.code,
            content.contentType, content.response)

            client.send(response)
        except CatchableError as e:
            let response: string = responseHTTPHeader(500, "text/plain",
            e.getStackTrace() & "\n" & e.msg)
            debug response
            client.send(response)

    client.close()
    debug fmt"It took {(cpuTime() - time_before_processing) * 1000}ms to send"
