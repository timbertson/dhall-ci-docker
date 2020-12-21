let Image
    : Type
    = { name : Text, tag : Optional Text }

let default = { tag = None Text }

let render =
      \(image : Image) ->
        let tag =
              merge { Some = \(tag : Text) -> ":${tag}", None = "" } image.tag

        in  "${image.name}${tag}" : Text

let tag =
      \(image : Image) ->
        merge { Some = \(tag : Text) -> tag, None = "latest" } image.tag

let Module = { Type = Image, default, render, tag }

let _testNoTag = assert : Module.render Module::{ name = "ubuntu" } === "ubuntu"

let _testTag =
        assert
      :     Module.render Module::{ name = "ubuntu", tag = Some "latest" }
        ===  "ubuntu:latest"

let _testDigest =
        assert
      :     Module.render Module::{ name = "ubuntu", tag = Some "latest" }
        ===  "ubuntu:latest"

in  Module
