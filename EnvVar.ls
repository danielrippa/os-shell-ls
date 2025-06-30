
  do ->

    { create-shell } = dependency 'os.win32.com.Shell'
    { each-enumeration-item } = dependency 'os.win32.com.Enumerable'
    { first-index-of, string-interval, string-split-by-first-segment } = dependency 'unsafe.String'
    { type } = dependency 'reflection.Type'

    shell = create-shell!

    expand = -> shell.ExpandEnvironmentStrings it

    get-env-var = (env-name, var-name) -> (shell.Environment env-name) var-name
    set-env-var = (env-name, varname, varvalue) -> env = shell.Environment env-name ; ``env(varname)=varvalue``

    environment-names = <[ user system volatile process ]>

    environment = (env-name) ->

      name: env-name

      get: -> get-env-var @name, it
      set: (var-name, var-value) -> set-env-var @name, var-name, var-value
      add: (var-name, var-value) -> value = get-env-var @name, var-name ; set-env-var @name, var-name, "#value#var-value"

      remove: (var-name) !-> shell.Environment @name .Remove var-name

    [ user, system, volatile, process ] = [ (environment name) for name in environment-names ]

    get = -> query = "%#it%" ; value = expand query ; unless value is query => value

    each-env-var = (env-name, fn) !->

      type '< String >' env-name ; type '< Function >' fn

      return unless env-name in environment-names

      each-enumeration-item (shell.Environment env-name), (env-var-string, index, enumerable, enumerator) ->

        [ env-var-name, env-var-value ] = env-var-string `string-split-by-first-segment` '='

        fn env-var-name, env-var-value, env-var-string, index, enumerable, enumerator

    {
      environment, user, system, volatile, process,
      expand,
      get,
      each-env-var
    }

