import std/posix
import os
import strutils
import strformat
import handle

var sockfd: SocketHandle
var count: int

proc handle_sigint(sig: cint) {.noconv.} =
    echo "SIGINT received, terminating gracefully."
    discard close(sockfd)
    quit()

proc handle_segfault(sig: cint) {.noconv.} =
    echo "GOT SEGFAULT'D - " & $count & "ATTEMPTS TO CRASH"
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

    signal(cast[cint](SIGINT), handle_sigint)
    signal(cast[cint](SIGSEGV), handle_segfault)

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
    
            echo fmt"Received from {client_ip}"

            var thread_ip: Pthread
            discard pthread_create(addr thread_ip, nil, handleClient, cast[pointer](client_sock))
            discard pthread_detach(thread_ip)
            count+=1
            echo "COUNT " & $count
        except CatchableError as e:
            echo e.getStackTrace()
            echo e.msg
            echo "most likely got Segmentation Fault'd - " & $count & " attempts to crash"
            break

    discard close(sockfd)

when isMainModule:
    main()
