-- (docker tags can't have slashes, so we replace them with dashes)
\(tag : Text) -> "\$(echo \"${tag}\" | tr / -)"
