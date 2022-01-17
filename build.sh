#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)"
rm -f tic-tac-toe
../Odin/odin build tic-tac-toe.odin -vet -debug -extra-linker-flags:'/home/jim/projects/stb/libstb_image.a'
