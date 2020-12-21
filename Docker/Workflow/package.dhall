let CI = ../../dependencies/CI.dhall

let Workflow = CI.Workflow

let Step = Workflow.Step

let Script = ../Script.dhall

let Registry = ../Registry.dhall

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
      { repository = Registry.github
      , username = "\$GITHUB_ACTOR"
      , secret = "GITHUB_TOKEN"
      }

let loginToGithub = login githubCredentials : Step.Type

in  { login
    , githubCredentials
    , loginToGithub
    , Project = ./Project.dhall
    , branchImage = ./branchImage.dhall
    , commitImage = ./commitImage.dhall
    , branchName = ./branchName.dhall
    }
