sources:
  cabal build all

build: sources
  cabal run hakyll-site build 

rebuild: sources
  cabal run hakyll-site rebuild

watch: sources
  cabal run hakyll-site watch 