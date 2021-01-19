{- Project is an abstraction on top of the base Docker.Build functionality.
   It covers the full CI process for a docker build, including:
    - labelling images with both branch and commit
    - pulling and pushing images
    - individually building each stage in a multi-stage docker build (necessary for effective caching)
-}
let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Image = ./Image.dhall

let Build = ./Build.dhall

let Script = ./Script.dhall

let map = Prelude.List.map

let addSuffix =
      \(suffix : Text) ->
      \(base : Image.Type) ->
        base // { tag = Some "${Image.tag base}${suffix}" }

let _testAddSuffix =
        assert
      :     addSuffix "1" Image::{ name = "app", tag = Some "commit" }
        ===  Image::{ name = "app", tag = Some "commit1" }

let _testAddSuffixToEmpty =
        assert
      :     addSuffix "1" Image::{ name = "app" }
        ===  Image::{ name = "app", tag = Some "latest1" }

let Stage =
      let Stage =
            { tagSuffix : Text, target : Optional Text, desc : Optional Text }

      let Chained =
          {- Combines a stage with its place in the chain (i.e. previous stages).
             Mainly used internally, but exposed for integration with GithubWorkflow
          -}

            { stage : Stage, previousStages : List Stage }

      let default =
            { desc = None Text, tagSuffix = "", target = None Text } : Stage

      let builder =
              { tagSuffix = "-builder"
              , target = Some "builder"
              , desc = Some "builder"
              }
            : Stage

      let runtime =
              default // { target = Some "runtime", desc = Some "runtime" }
            : Stage

      let single = default

      let image =
            \(stage : Stage) ->
            \(image : Image.Type) ->
              addSuffix stage.tagSuffix image

      let accumulateChained =
            \(stage : Stage) ->
            \(acc : List Chained) ->
              let previousStages =
                    Prelude.List.map
                      Chained
                      Stage
                      (\(chained : Chained) -> chained.stage)
                      acc

              in  acc # [ { stage, previousStages } ]

      let chain =
            \(stages : List Stage) ->
                Prelude.List.fold
                  Stage
                  (Prelude.List.reverse Stage stages)
                  (List Chained)
                  accumulateChained
                  ([] : List Chained)
              : List Chained

      let _testChain =
            let stage1 = default // { target = Some "one" }

            let stage2 = default // { target = Some "two" }

            let stage3 = default // { target = Some "three" }

            in    assert
                :     chain [ stage1, stage2, stage3 ]
                  ===  [ { stage = stage1, previousStages = [] : List Stage }
                       , { stage = stage2
                         , previousStages = [ stage1 ] : List Stage
                         }
                       , { stage = stage3
                         , previousStages = [ stage1, stage2 ] : List Stage
                         }
                       ]

      in  { Type = Stage
          , Chained
          , default
          , single
          , runtime
          , builder
          , chain
          , image
          }

let Project =
    {- General CI information applying to
    a given project / repo -}
      { image : Image.Type
      , branchImage : Image.Type
      , commitImage : Image.Type
      , build : Build.Type
      }

let default = { build = Build.default }

let sampleProject =
      let image = Image::{ name = "myApp" }

      let commit = "abc123"

      in        default
            //  { image
                , branchImage = image // { tag = Some "branch" }
                , commitImage = image // { tag = Some commit }
                }
          : Project

let addStageSuffix =
      \(stage : Stage.Type) ->
        map Image.Type Image.Type (addSuffix stage.tagSuffix)

let registryCacheFrom =
    {- The registry images we'll --cache-from -}
      \(project : Project) ->
      \(stage : Stage.Type) ->
        addStageSuffix stage [ project.image, project.branchImage ]

let previousStageCacheFrom =
      \(project : Project) ->
      \(chainedStage : Stage.Chained) ->
        let previousStageSuffixes =
              map
                Stage.Type
                Text
                (\(stage : Stage.Type) -> stage.tagSuffix)
                chainedStage.previousStages

        in  map
              Text
              Image.Type
              (\(suffix : Text) -> addSuffix suffix project.commitImage)
              previousStageSuffixes

let tags =
    {- The tags we'll assign to this image -}
      \(project : Project) ->
      \(stage : Stage.Type) ->
        addStageSuffix stage [ project.commitImage, project.branchImage ]

let buildOptions =
    {- Computes the Docker.Build.Type for a Stage.Chained -}
      \(project : Project) ->
      \(chainedStage : Stage.Chained) ->
        let stage = chainedStage.stage

        let cacheFrom =
                registryCacheFrom project stage
              # previousStageCacheFrom project chainedStage

        in        project.build
              //  { tags = tags project stage
                  , cacheFrom
                  , target = stage.target
                  }
            : Build.Type

let _testBuildOptions =
        assert
      :     buildOptions
              sampleProject
              { stage = Stage::{ tagSuffix = "-2" }
              , previousStages =
                [ Stage::{ tagSuffix = "-0" }, Stage::{ tagSuffix = "-1" } ]
              }
        ===      sampleProject.build
             //  { tags =
                   [ addSuffix "-2" sampleProject.commitImage
                   , addSuffix "-2" sampleProject.branchImage
                   ]
                 , cacheFrom =
                   [ addSuffix "-2" sampleProject.image
                   , addSuffix "-2" sampleProject.branchImage
                   , addSuffix "-0" sampleProject.commitImage
                   , addSuffix "-1" sampleProject.commitImage
                   ]
                 }

let needsPull =
      \(buildMode : Build.Mode) ->
        merge
          { Buildkit = False, BuildkitLocal = True, Docker = True }
          buildMode

let buildChained =
    {- Advanced functionality, you probably want buildSimpleProject / buildMultiStageProject -}
      \(project : Project) ->
      \(chainedStage : Stage.Chained) ->
        let pull =
              if    needsPull project.build.mode
              then  Bash.join
                      ( Prelude.List.map
                          Image.Type
                          Bash.Type
                          Script.tryPull
                          (registryCacheFrom project chainedStage.stage)
                      )
              else  [] : Bash.Type

        let buildAndPush =
              Script.buildAndPush (buildOptions project chainedStage)

        in  pull # buildAndPush

let pushProjectStageToLatest =
      \(project : Project) ->
      \(stage : Stage.Type) ->
        let stageLatest = addSuffix stage.tagSuffix project.image

        let stageCommit = addSuffix stage.tagSuffix project.commitImage

        in  Bash.join
              [ Script.tag stageCommit stageLatest, Script.push stageLatest ]

let _testPushProjectStageToLatest =
        assert
      :     pushProjectStageToLatest sampleProject Stage.builder
        ===  [ "docker tag \"myApp:abc123-builder\" \"myApp:latest-builder\""
             , "docker push \"myApp:latest-builder\""
             ]

let buildMultiStageProject =
      \(project : Project) ->
      \(stages : List Stage.Type) ->
        Bash.join
          ( map
              Stage.Chained
              Bash.Type
              (buildChained project)
              (Stage.chain stages)
          )

let buildSimpleProject =
      \(project : Project) -> buildMultiStageProject project [ Stage.single ]

in  { Type = Project
    , default
    , Stage
    , buildChained
    , pushProjectStageToLatest
    , buildSimpleProject
    , buildMultiStageProject
    }
