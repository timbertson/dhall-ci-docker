let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Workflow = CI.Workflow

let Step = Workflow.Step

let Script = ./Script.dhall

let Repository = ./Repository.dhall

let login =
      \(options : Script.Login) ->
              Step.bash
                ( Script.login
                    { repository = options.repository
                    , username = options.username
                    , secret = "\$DOCKER_PASSWORD"
                    }
                )
          //  { name = Some "Login to ${options.repository}"
              , env = Some
                  ( toMap
                      { DOCKER_PASSWORD = "\${{ secrets.${options.secret} }}" }
                  )
              }
        : Step.Type

let githubCredentials =
      { repository = Repository.github
      , username = "\$GITHUB_ACTOR"
      , secret = "GITHUB_TOKEN"
      }

let loginToGithub = login githubCredentials : Step.Type

in  { login, githubCredentials, loginToGithub }
