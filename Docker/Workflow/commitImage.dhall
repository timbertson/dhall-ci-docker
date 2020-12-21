-- docker image labelled with the current commit
let Image = ../Image.dhall

in  \(base : Image.Type) -> base // { tag = Some "\$GITHUB_SHA" } : Image.Type
