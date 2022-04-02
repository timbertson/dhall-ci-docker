    (   env:DHALL_CI
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/1230f1e9299d80c7a0292ef70eaa06ce5c0f0244/package.dhall
          sha256:12954ab5215e3b11c3cb273d5953ceca7e96604d2612e0db2d1f2ffc9b1254e2
    )
/\  { Git =
          env:DHALL_CI_GIT
        ? https://raw.githubusercontent.com/timbertson/dhall-ci-git/e4e2cb45bdaa7bf2d4f6054feaf814fd1d6986b1/package.dhall
            sha256:f8071927cf5f6ae54968ee72806efa4b2efb9cbd1916fb46d3c1c1816465ea52
    }
