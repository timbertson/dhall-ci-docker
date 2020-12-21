-- The docker type is pretty loose, since Dockerfile is plain text and not yaml.
-- We could strictly type all of the directives, but it's easier to just provide builders
-- for commonly used directives and use `raw` as an escape hatch
let Prelude = ../dependencies/Prelude.dhall

let Image = ./Image.dhall

let Step
    : Type
    = { raw : Text }

let raw = \(raw : Text) -> { raw } : Step

let prefix =
      \(prefix : Text) ->
      \(instruction : Text) ->
        { raw = "${prefix} ${instruction}" }

let formatStringList =
      \(list : List Text) ->
        let quoted =
              Prelude.Text.concatSep
                ", "
                (Prelude.List.map Text Text Text/show list)

        in  "[ ${quoted} ]"

let Module =
      { Type = Step
      , from = \(base : Image.Type) -> raw "FROM ${Image.render base}"
      , fromAs =
          \(base : Image.Type) ->
          \(name : Text) ->
            raw "FROM ${Image.render base} as ${name}"
      , workdir = prefix "WORKDIR"
      , user = prefix "USER"
      , copy = \(src : Text) -> \(dest : Text) -> raw "COPY ${src} ${dest}"
      , copyTo =
          \(src : Text) ->
          \(prefix : Text) ->
            raw "COPY ${src} ${prefix}/${src}"
      , copyFrom =
          \(image : Text) ->
          \(src : Text) ->
          \(dest : Text) ->
            raw "COPY --from=${image} ${src} ${dest}"
      , cmd = \(args : List Text) -> raw "CMD ${formatStringList args}"
      , entrypoint =
          \(args : List Text) -> raw "ENTRYPOINT ${formatStringList args}"
      , run = \(args : List Text) -> raw "RUN ${formatStringList args}"
      , runBash = \(sh : Text) -> raw "RUN ${sh}"
      , render = \(step : Step) -> step.raw
      , arg = prefix "ARG"
      , env = \(key : Text) -> \(value : Text) -> raw "ENV ${key}=${value}"
      }

let _testFrom =
        assert
      : Module.render (Module.from Image::{ name = "ubuntu" }) === "FROM ubuntu"

in  Module
