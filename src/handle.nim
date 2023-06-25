import std/posix
import strutils
import header
import version

const BUFFER_SIZE = 1024

type handleHTTPEventResponse = ref object
    response: string
    contentType: string
    code: int

proc getMimeType(fileName: string): string =
    # implictly index.html
    let ext_r = fileName.split('.')
    let ext = ext_r[ext_r.high]
    if ext.len == 0:
        return "text/html"
    case ext
    of "jpeg":
        return "image/jpeg"
    of "jpg":
        return "image/jpeg"
    of "png":
        return "image/png"
    of "ico":
        return "image/x-icon"
    of "html":
        return "text/html"
    of "htm":
        return "text/html"
    else:
        return "text/plain"

type HTTPRequest = ref object
    METHOD: string
    PATH: string
    HTTP: string

proc getHTTPRequest(input: string): HTTPRequest =
    var r: HTTPRequest = HTTPRequest()

    let line = input.splitLines()[0]
    let http_request = line.split(" ")
    case http_request[0].toLower()
    of "get":
        discard
    else:
        raise newException(ValueError, "not implemented yet")

    r.METHOD = http_request[0]
    r.PATH = http_request[1]
    r.HTTP = http_request[2]
    return r
    


proc handleHTTPEvent(string_buffer: string): handleHTTPEventResponse =

    var r: handleHTTPEventResponse = handleHTTPEventResponse()

    var request: HTTPRequest = getHTTPRequest($string_buffer)
    let pathes = request.PATH.split("/")
    var file: string
    try:
        file = pathes[pathes.high]
    except IndexDefect:
        file = ""
    if file.len() == 0:
        file = "index.html"
    echo "The file is " & file & " on path " & pathes.join("/")
    try:
        let response = readFile("public/" & file)
        if file == "index.html":
            r.response = response.replace("{{NIMO}}", "Nimo v" & $version_pkg)
        else:
            r.response = response
        echo "Response size is " & formatSize(r.response.len)
        r.contentType = getMimeType(file)
        r.code = 200
    except CatchableError:
        r.response = "Not found"
        r.contentType = "text/plain"
        r.code = 404
    return r

proc handleClient*(arg: pointer): pointer  {.noconv.} =
    let client_fd = SocketHandle(cast[int](arg))
    var buffer = alloc(BUFFER_SIZE * sizeof(char))

    var bytes_received = recv(client_fd, buffer, BUFFER_SIZE, 0)

    if bytes_received > 0:
        let string_buffer = cast[cstring](buffer)
        try:
            #echo string_buffer

            let content: handleHTTPEventResponse = handleHTTPEvent($string_buffer)
            let response: string = responseHTTPHeader(content.code, content.contentType, content.response)

            discard send(client_fd, cstring(response), response.len, 0)
        except CatchableError as e:
            let response: string = responseHTTPHeader(500, "text/plain", e.getStackTrace() & "\n" & e.msg)
            echo response
            discard send(client_fd, cstring(response), response.len, 0)

    dealloc(buffer)
    discard close(client_fd)