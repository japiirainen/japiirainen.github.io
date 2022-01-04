{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified GHC.IO.Encoding as E
import Hakyll
import Text.Pandoc.Options

main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  hakyllWith config $ do
    match
      ( "static/*"
          .||. "static/*/*"
          .||. "static/*/*/*"
          .||. "static/*/*/*/*"
          .||. "static/*/*/*/*/*"
          .||. "static/*/*/*/*/*/*"
      )
      $ do
        route idRoute
        compile copyFileCompiler

    match "img/*" $ do
      route idRoute
      compile copyFileCompiler

    match "favicon/*" $ do
      route $ customRoute $ drop 8 . toFilePath
      compile copyFileCompiler

    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    match (fromList ["about.md", "contact.md"]) $ do
      route $ setExtension "html"
      compile $
        pandocCompiler
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    match "posts/*" $ do
      route $ setExtension "html"
      compile $
        pandocMathCompiler
          >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= saveSnapshot "content"
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let archiveCtx =
              listField "posts" postCtx (return posts)
                `mappend` constField "title" "Archives"
                `mappend` defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" archiveCtx
          >>= relativizeUrls

    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <-
          fmap (take 10) . recentFirst
            =<< loadAllSnapshots "posts/*" "content"
        renderAtom myFeedConfiguration feedCtx posts

    create ["rss.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <-
          fmap (take 10) . recentFirst
            =<< loadAllSnapshots "posts/*" "content"
        renderRss myFeedConfiguration feedCtx posts

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let indexCtx =
              listField "posts" postCtx (return posts)
                `mappend` constField "title" "Home"
                `mappend` defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs",
      deployCommand = "publish.sh"
    }

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration =
  FeedConfiguration
    { feedTitle = "Feed title",
      feedDescription = "This feed lists the latest blog posts",
      feedAuthorName = "Joona Piirainen",
      feedAuthorEmail = "joona.piirainen@gmail.com",
      feedRoot = "https://japiirainen.com/"
    }

pandocMathCompiler =
  let mathExtensions =
        extensionsFromList
          [ Ext_tex_math_dollars,
            Ext_tex_math_double_backslash,
            Ext_latex_macros
          ]
      defaultExtensions = writerExtensions defaultHakyllWriterOptions
      writerOptions =
        defaultHakyllWriterOptions
          { writerExtensions = mathExtensions <> defaultExtensions,
            writerHTMLMathMethod = MathJax ""
          }
   in pandocCompilerWith defaultHakyllReaderOptions writerOptions