import os
import std/parseopt
import strutils
import strformat

const help = """
nimo - a little HTTP server to serve static website

Usage: nimo <directory> [-p:number]

--help, -h              -> Shows this help page
--version, -v           -> Shows version

--port, -p     -> Set port, defaults to 8000
"""

const version = """
version 0.1.0
"""

type
    ArgParser* = ref object
        directory*: string
        port*: int

proc getParse*(): ArgParser =
    var argsDict: ArgParser = ArgParser(port: 8000)
    for kind, key, val in getopt(commandLineParams()):
        case kind
            of cmdEnd: discard
            of cmdArgument:
                argsDict.directory = key.absolutePath
            of cmdLongOption, cmdShortOption:
                case key
                    of "help", "h":
                        echo help
                        quit()
                    of "version", "v":
                        echo version
                        quit()
                    of "port", "p":
                        argsDict.port = val.parseInt()
                        break
                    else:
                        echo help
                        quit()

    if not dirExists(argsDict.directory):
        quit(fmt"Cannot find that directory ({argsDict.directory})", 1)
    return argsDict
