
  do ->

    { type } = dependency 'reflection.Type'
    { array-size, drop-array-items } = dependency 'unsafe.Array'

    WScript.Arguments.Unnamed

      arg = -> ..Item it
      argc = ..Count

    argv = [ (arg index) for index til argc ]

    parse-argv = ->

      type '[ *:String ]' it

      [ command, args ] = switch array-size it

        | 0 => [ void, [] ]

        else [ it.0, (drop-array-items it, (item, index) -> index is 0) ]

      { command, args }

    {
      arg, argc, argv,
      parse-argv
    }