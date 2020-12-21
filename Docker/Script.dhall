let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

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

in  { login, Login }
