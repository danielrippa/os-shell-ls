
  do ->

    { stderr } = dependency 'os.shell.IO'
    { type } = dependency 'reflection.Type'
    { lf } = dependency 'unsafe.Constants'
    { drop-array-items } = dependency 'unsafe.Array'
    { name-from-path } = dependency 'os.filesystem.Path'

    WScript

      ..Arguments.Unnamed

        arg = -> ..Item it
        argc = ..Count

      script-filepath = ..ScriptFullName
      script-name = name-from-path ..ScriptName

      exit = (errorlevel = 0) -> ..Quit errorlevel

    fail = (lines, errorlevel = 1) -> type '[ *:String ]' lines ; lines |> (* "#lf") |> stderr ; exit errorlevel

    argv = [ (arg index) for index til argc ]

    parse-argv = ->

      type '[ *:String ]' it

      [ command, args ] = switch it.length

        | 0 => [ void, [] ]

        else [ it.0, (drop-array-items it, (item, index) -> index is 0) ]

      { command, args }

    {
      script-filepath, script-name,
      exit, fail,
      argc, argv,
      parse-argv
    }