-- docker image labeled with the current branch
-- (can't have slashes, so we replace them with dashes)
let Image = ../Image.dhall

let branchName = ./branchName.dhall

let encodeTag = ../encodeTag.dhall

in  \(base : Image.Type) ->
      base // { tag = Some (encodeTag branchName) } : Image.Type
