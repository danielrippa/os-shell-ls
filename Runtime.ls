
  do ->

    { map-array-items } = dependency 'unsafe.Array'
    { object-from-member-pairs } = dependency 'unsafe.Object'
    { camel-case, capital-case } = dependency 'unsafe.StringCase'

    value-name = -> "ScriptEngine#{ capital-case it }#{ if it is '' then '' else 'Version' }"

    member-name = -> if it is '' then 'language' else "#{ it }-version"

    pair-as-member-pair = ([ key, value ]) -> [ (member-name key), eval "#value()" ]

    pairs-as-member-pairs = -> map-array-items it, pair-as-member-pair

    names-as-pairs = -> map-array-items it, name-as-pair

    value-as-pair = -> [ it, value-name it ]

    values-as-pairs = -> map-array-items it, value-as-pair

    [ '' ] ++ <[ build major minor ]> |> values-as-pairs |> pairs-as-member-pairs |> object-from-member-pairs



