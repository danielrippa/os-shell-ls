
  do ->

    { create-debug-writer } = dependency 'os.win32.com.DebugWriter'

    [ stderr, stdout ] = do ->

      stream-write = (stream-name) -> -> WScript[stream-name].Write [ (arg) for arg in arguments ] * ''

      [ (stream-write stream-name) for stream-name in <[ StdErr StdOut ]> ]

    read-stdin = (count) -> WScript.StdIn.Read count

    debug-writer = create-debug-writer!

    debug = -> debug-writer.Write [ (arg) for arg in arguments ] * ' '

    {
      stderr, stdout,
      read-stdin,
      debug
    }