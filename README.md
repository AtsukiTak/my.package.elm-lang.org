my.package.elm-lang.org
===

You can host your private package's "docs.json" and "README.md".

## Features

- Static
- non-versioning


## How to use

1. Copy your package's "docs.json" and "README.md" files in "www/packages/[your name]/[package name]/" directory.
1. Run `make`.
1. Run `make docker`. Make sure you have automake and docker.
1. Access to `localhost:8000/packages/[your name]/[package name]`
