import net
import std/posix
import os
import strformat
import handle
import threadpool
import parser

var server: Socket

const NIMO_VERSION = "0.1.0"

proc handle_sigint(sig: cint) {.noconv.} =
    echo "SIGINT received, terminating gracefully."
    server.close()
    quit()


proc main(): void =
    let arg: ArgParser = getParse()

    echo fmt"Using Nimo version {NIMO_VERSION}"
    server = newSocket()

    if paramCount() < 1:
        echo "not enough arguments, exiting."
        quit(QuitFailure)

    let port: int = arg.port

    server.bindAddr(Port(port))
    server.setSockOpt(OptReuseAddr, true)

    signal(cast[cint](SIGINT), handle_sigint)

    server.listen()

    echo fmt"Server listening on http://localhost:{port}"

    var client: Socket = new(Socket)
    var address: string
    while true:
        try:
            server.acceptAddr(client, address)
            echo fmt"Received from {address}"
            spawn handleClient(client)
        except CatchableError as e:
            echo e.getStackTrace()
            echo e.msg
            break

    server.close()

when isMainModule:
    main()
