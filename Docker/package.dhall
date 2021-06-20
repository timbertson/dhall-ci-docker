let Prelude = ../dependencies/Prelude.dhall

let Step = ./Step.dhall

in      ./Script.dhall
    /\  { Project = ./Project.dhall
        , Registry = ./Registry.dhall
        , Run = ./Run.dhall
        , Image = ./Image.dhall
        , Step
        , Build = ./Build.dhall
        , Type = List Step.Type
        , render =
            \(steps : List Step.Type) ->
              Prelude.Text.concatSep
                "\n"
                (Prelude.List.map Step.Type Text Step.render steps)
        }
