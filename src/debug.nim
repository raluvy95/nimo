proc debug*(arg: varargs[string, `$`]): void =
    when not defined(release):
        debugEcho arg