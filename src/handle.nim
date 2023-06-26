import strutils
import header
import std/[posix, uri, times, mimetypes, sequtils]
import strformat
import debug

const BUFFER_SIZE = 1024

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
        return getMimeType(newMimetypes(), ext)

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

    var request: HTTPRequest = getHTTPRequest($string_buffer)
    let pathes = request.PATH.path.split("/")
    var file: string
    try:
        file = pathes[pathes.high]
    except IndexDefect:
        file = ""
    if file.len() == 0:
        file = "index.html"
    debug "The file is " & file & " on path " & pathes.join("/")
    try:
        let response = readFile("public/" & file)
        if file == "index.html":
            r.response = response.replace("{{NIMO}}", "Nimo v0.1.0")
        else:
            r.response = response
        debug "Response size is " & formatSize(r.response.len)
        r.contentType = getMime(file)
        r.code = 200
    except CatchableError:
        r.response = "Not found"
        r.contentType = "text/plain"
        r.code = 404
    return r

proc handleClient*(client: SocketHandle, version: string): void {.thread.} =
    var time_before_processing = cpuTime()
    var buffer = alloc(BUFFER_SIZE * sizeof(char))

    var bytes_received = recv(client, buffer, BUFFER_SIZE, 0)

    if bytes_received > 0:
        let string_buffer = cast[cstring](buffer)
        try:
            #echo string_buffer

            let content: handleHTTPEventResponse = handleHTTPEvent($string_buffer)
            let response: string = responseHTTPHeader(content.code, content.contentType, content.response)

            discard send(client, cstring(response), response.len, 0)
        except CatchableError as e:
            let response: string = responseHTTPHeader(500, "text/plain", e.getStackTrace() & "\n" & e.msg)
            debug response
            discard send(client, cstring(response), response.len, 0)

    dealloc(buffer)
    discard close(client)
    debug fmt"It took {(cpuTime() - time_before_processing) * 1000}ms to send"