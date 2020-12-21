-- docker image labeled with the current branch
-- (can't have slashes, so we replace them with dashes)
let Image = ../Image.dhall

let branchName = ./branchName.dhall

in  \(base : Image.Type) ->
      base // { tag = Some "\$(echo \"${branchName}\" | tr / -)" } : Image.Type
