let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Image = ./Image.dhall

let Build = ./Build.dhall

let Run = ./Run.dhall

let Bash = CI.Bash

let Login = { repository : Text, username : Text, secret : Text }

let login =
    -- use of EOF heredoc prevents the key from being echoed with `set -x`
      \(login : Login) ->
        [ "docker login -u \"${login.username}\" --password-stdin ${login.repository} <<EOF"
        , ''
          ${login.secret}
          EOF''
        ]

let _pullCmd = \(image : Image.Type) -> "docker pull \"${Image.render image}\""

let pull = \(image : Image.Type) -> [ _pullCmd image ]

let tryPull = \(image : Image.Type) -> [ "${_pullCmd image} || true" ]

let build = \(options : Build.Type) -> [ Build.command options ]

let run = \(options : Run.Type) -> Run.script options

let runInCwd =
      \(options : Run.Type) ->
        Run.script
          (     options
            //  { flags =
                      options.flags
                    # [ "--volume", "\$PWD:/cwd", "--workdir=/cwd" ]
                }
          )

let push = \(image : Image.Type) -> [ "docker push \"${Image.render image}\"" ]

let buildAndPush =
      \(options : Build.Type) ->
        let pushCommands =
              Prelude.List.map Image.Type Bash.Type push options.tags

        in  Bash.join ([ build options ] # pushCommands)

let freeze =
      \(image : Image.Type) ->
        "\$(docker inspect --format='{{index .RepoDigests 0}}' \"${Image.render
                                                                     image}\")"

let tag =
      \(image : Image.Type) ->
      \(tag : Image.Type) ->
        [ "docker tag \"${Image.render image}\" \"${Image.render tag}\"" ]

in  { login
    , Login
    , pull
    , tryPull
    , build
    , run
    , runInCwd
    , push
    , buildAndPush
    , freeze
    , tag
    , encodeTag = ./encodeTag.dhall
    }
