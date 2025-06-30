
  do ->

    { create-shell } = dependency 'os.win32.com.Shell'
    { write-textfile } = dependency 'os.filesystem.TextFile'
    { compose-filename } = dependency 'os.filesytem.File'
    { lines-as-string } = dependency 'unsafe.Text'
    { try-catch-finally } = dependency 'runtime.Error'

    create-lnk-shortcut = (filepath, target-path) ->

      try-catch-finally -> filepath |> create-shell!CreateShortcut |> (.TargetPath = target-path) |> (.Save!)

    create-url-shortcut = (filepath, url) ->

     try-catch-finally -> <[ [InternetShortcut] ]> ++ [ "URL=#url" ] |> lines-as-string |> write-textfile filepath, _

    {
      create-lnk-shortcut,
      create-url-shortcut
    }