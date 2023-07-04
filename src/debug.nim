proc debug*(arg: varargs[string, `$`]): void =
    when not defined(release):
        for a in arg:
            debugEcho a
