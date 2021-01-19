{-
Options for building a dockerfile.
-}
let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Image = ./Image.dhall

let List/map = Prelude.List.map

let Mode =
    {-|

     * Buildkit:
       Use online cache, with BUILDKIT_INLINE_CACHE=1.
       This is the fastest, but online caching doesn't seem to work in all cases.

     * BuildkitLocal:
       As above, but attempts to pull cache images before building. This is
       slower because it downloads all layers, even when there's no cache match.

     * Docker:
       Traditional docker build, i.e. buildkit disabled
    -}
      < Buildkit | BuildkitLocal | Docker >

let usesBuildkit =
      \(mode : Mode) ->
        merge { Buildkit = True, BuildkitLocal = True, Docker = False } mode

let Build =
        { buildArgs : List Text
        , dockerfile : Text
        , path : Text
        , cacheFrom : List Image.Type
        , target : Optional Text
        , tags : List Image.Type
        , mode : Mode
        }
      : Type

let default =
      { buildArgs = [] : List Text
      , dockerfile = "Dockerfile"
      , path = "."
      , cacheFrom = [] : List Image.Type
      , target = None Text
      , tags = [] : List Image.Type
      , mode = Mode.Docker
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

        let inlineCacheArg =
              if    usesBuildkit options.mode
              then  [ "BUILDKIT_INLINE_CACHE=1" ]
              else  [] : List Text

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
        let prefix =
              if usesBuildkit options.mode then "env DOCKER_BUILDKIT=1 " else ""

        in  "${prefix}docker ${Bash.doubleQuoteArgs (arguments options)}"

in  { Type = Build, Mode, default, command, arguments }
