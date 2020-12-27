let Prelude = ../../dependencies/Prelude.dhall

let CI = ../../dependencies/CI.dhall

let Bash = CI.Bash

let Image = ../Image.dhall

let Build = ../Build.dhall

let Step = CI.Workflow.Step

let Project = ../Project.dhall

let commitImage = ./commitImage.dhall

let Options =
      { image : Image.Type
      , build : Build.Type
      , stages : List Project.Stage.Type
      }

let default = { build = Build.default, stages = [ Project.Stage.single ] }

let encodeTag = ../encodeTag.dhall

let branchImage =
    -- we could use ./branchImage.dhall, but that's a mouthful in order to be
    -- valid in all contexts. Since we control the full step we can
    -- use an environment variable for more readable output
      \(base : Image.Type) ->
        base // { tag = Some (encodeTag "\${BRANCH_REF#refs/heads/}") }

let projectConfig =
      \(options : Options) ->
          { image = options.image
          , branchImage = branchImage options.image
          , commitImage = commitImage options.image
          , build = options.build
          }
        : Project.Type

let steps =
      \(options : Options) ->
        let project = projectConfig options

        let buildStep =
              \(chainedStage : Project.Stage.Chained) ->
                let nameSuffix =
                      merge
                        { Some = \(desc : Text) -> " [${desc}]", None = "" }
                        chainedStage.stage.desc

                in      Step.bash (Project.buildChained project chainedStage)
                    //  { name = Some "Docker build${nameSuffix}"
                        , env = Some
                            ( toMap
                                { BRANCH_REF =
                                    "\${{ github.head_ref || github.ref }}"
                                }
                            )
                        }

        let pushLatestCommands =
              Prelude.List.map
                Project.Stage.Type
                Bash.Type
                (Project.pushProjectStageToLatest project)
                options.stages

        let pushLatestStep =
                  Step.bash (Bash.join pushLatestCommands)
              //  { name = Some "Docker push :${Image.tag options.image}"
                  , `if` = Some CI.Workflow.Expr.isPushToMain
                  }

        in      Prelude.List.map
                  Project.Stage.Chained
                  Step.Type
                  buildStep
                  (Project.Stage.chain options.stages)
              # [ pushLatestStep ]
            : List Step.Type

in  { Type = Options, default, steps }
