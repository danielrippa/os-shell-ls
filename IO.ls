
  do ->

    { create-debug-writer } = dependency 'os.win32.com.DebugWriter'

    [ stderr, stdout ] = do ->

      stream-write = (stream-name) -> -> WScript[stream-name].Write [ (arg) for arg in arguments ] * ''

      [ (stream-write stream-name) for stream-name in <[ StdErr StdOut ]> ]

    read-stdin-chars = (count) -> WScript.StdIn.Read count

    read-stdin = -> WScript.StdIn => loop => break if ..AtEndOfStream ; ..ReadAll!

    debug-writer = create-debug-writer!

    debug = -> debug-writer.Write [ (arg) for arg in arguments ] * ' '

    {
      stderr, stdout,
      read-stdin-chars, read-stdin,
      debug
    }