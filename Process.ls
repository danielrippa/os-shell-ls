
  do ->

    { type } = dependency 'reflection.Type'
    { create-temporary-file } = dependency 'os.filesystem.TemporaryFile'
    { create-shell } = dependency 'os.win32.com.Shell'
    { double-quotes } = dependency 'unsafe.Circumfix'

    create-process = (executable, options, working-folder) ->

      type '< String >' executable ; type '[ *:String ]' options
      type '< String Undefined >' working-folder

      [ temp1, temp2 ] = [ (create-temporary-file!) for index til 2 ]

      command-line = "#executable #{ options * ' ' } > #{ double-quotes temp1.filepath } 2> #{ double-quotes temp2.filepath }"

      create-shell!

        ..CurrentDirectory = working-folder unless working-folder is void

        errorlevel = ..Run command-line, 0, yes

      [ stdout, stderr ] = [ (tempfile.read-and-remove!) for tempfile in [ temp1, temp2 ] ]

      { errorlevel, stdout, stderr, command-line, working-folder }

    {
      create-process
    }