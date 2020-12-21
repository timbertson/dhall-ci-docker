{-
Options for building a dockerfile.
-}
let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Image = ./Image.dhall

let List/map = Prelude.List.map

let Build =
        { buildArgs : List Text
        , dockerfile : Text
        , path : Text
        , cacheFrom : List Image.Type
        , target : Optional Text
        , tags : List Image.Type
        }
      : Type

let default =
      { buildArgs = [] : List Text
      , dockerfile = "Dockerfile"
      , path = "."
      , cacheFrom = [] : List Image.Type
      , target = None Text
      , tags = [] : List Image.Type
      }

let arguments =
      \(options : Build) ->
        let flag = \(name : Text) -> \(value : Text) -> "--${name}=${value}"

        let optFlag =
              \(name : Text) ->
              \(value : Optional Text) ->
                merge
                  { Some = \(value : Text) -> [ flag name value ]
                  , None = [] : List Text
                  }
                  value

        let buildArg = flag "build-arg"

        let inlineCacheArg = [ "BUILDKIT_INLINE_CACHE=1" ]

        let cacheFrom =
              \(image : Image.Type) -> flag "cache-from" (Image.render image)

        let tag = \(image : Image.Type) -> flag "tag" (Image.render image)

        in  Prelude.List.concat
              Text
              [ [ "build", "--progress=plain", flag "file" options.dockerfile ]
              , optFlag "target" options.target
              , List/map Text Text buildArg (options.buildArgs # inlineCacheArg)
              , List/map Image.Type Text cacheFrom options.cacheFrom
              , List/map Image.Type Text tag options.tags
              , [ options.path ]
              ]

let command =
      \(options : Build) ->
        "env DOCKER_BUILDKIT=1 docker ${Bash.doubleQuoteArgs
                                          (arguments options)}"

in  { Type = Build, default, command, arguments }
