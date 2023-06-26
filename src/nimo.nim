import std/posix
import os
import strutils
import strformat
import handle
import threadpool
import debug

var sockfd: SocketHandle

const NIMO_VERSION = "0.1.0"

proc handle_sigint(sig: cint) {.noconv.} =
    echo "SIGINT received, terminating gracefully."
    discard close(sockfd)
    quit()


proc main(): void =
    setStdIoUnbuffered()

    var servaddr = Sockaddr_in()
    
    sockfd = socket(AF_INET, SOCK_STREAM, 0)

    if sockfd == SocketHandle(-1):
        echo "socket creation failed..."
        quit(QuitFailure)
    
    if paramCount() < 1:
        echo "not enough arguments, exiting."
        quit(QuitFailure)
    
    let port: uint16 = uint16(paramStr(1).parseInt())
    
    servaddr.sin_family = 2
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY)
    servaddr.sin_port = htons(port)

    if bindSocket(sockfd, cast[ptr SockAddr](addr servaddr), cuint(sizeof(servaddr))) != 0:
        echo "There was problem binding socket"
        quit(QuitFailure)

    # TODO: Reuse address of socket
    # let optionValue: cint = 1
    # let optionSize: int = sizeof(int)

    # if setSockOpt(sockfd, SOL_SOCKET, SO_REUSEADDR, cast[ptr[byte]](addr optionValue), optionSize) < 0:
    #     echo "setSockOpt(SO_REUSEADDR) failed"
    #     quit(QuitFailure)

    signal(cast[cint](SIGINT), handle_sigint)

    discard listen(sockfd, 10)
    echo fmt"Server listening on port {port}"

    while true:
        try:
            var client_addr = Sockaddr_in()
            var client_size: SockLen = cuint(sizeof(client_addr))
            var client_sock = accept(sockfd, cast[ptr SockAddr](addr client_addr), addr client_size)
            if client_sock == SocketHandle(-1):
                echo "Error accepting connection..."
                continue

            var client_ip = newString(INET_ADDRSTRLEN)
            discard inet_ntop(AF_INET, addr client_addr.sin_addr, cstring(client_ip), INET_ADDRSTRLEN)
    
            debug fmt"Received from {client_ip}"

            spawn(handleClient(client_sock, NIMO_VERSION))
        except CatchableError as e:
            echo e.getStackTrace()
            echo e.msg
            break

    discard close(sockfd)

when isMainModule:
    main()
