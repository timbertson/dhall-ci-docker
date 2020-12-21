-- TODO add more specific conveniences, like `volume` etc
-- (and then only use `flags` as an escape hatch)
let CI = ../dependencies/CI.dhall

let Image = ./Image.dhall

let Bash = CI.Bash

let Run = { image : Image.Type, flags : List Text }

let default = { flags = [] : List Text }

let script =
    -- Use of EOF heredoc prevents escaping issues passing script to docker
      \(options : Run) ->
      \(script : Bash.Type) ->
        let args =
              Bash.doubleQuoteArgs
                (options.flags # [ Image.render options.image ])

        in    [ "docker run --rm -i ${args} bash ${Bash.strictFlags} <<EOF_runInDocker"
              ]
            # Bash.indent script
            # [ ''

                EOF_runInDocker''
              ]

in  { Type = Run, default, script }
