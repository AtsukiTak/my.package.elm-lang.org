my.package.elm-lang.org
===

You can host your private package's "docs.json" and "README.md".

## Features

- Static
- non-versioning


## How to use

1. Run `make`.
1. Copy your package's "docs.json" and "README.md" files in "www/assets/packages/[your name]/[package name]/" directory.
1. Add your package's information to "packages.json" in "www/assets/packages/packages.json" file.
1. Run `make docker`. Make sure you have automake and docker.
1. Access to `localhost:8000/packages/[your name]/[package name]`


## Demo

http://package.elm-lang.atsuki.me/
