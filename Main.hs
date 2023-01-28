{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (forM_)
import Data.Maybe (fromMaybe)
import Data.String
import Data.List (isSuffixOf)
import Hakyll
import System.Directory
import System.Exit
import System.FilePattern ((?==))
import System.FilePath
import System.Process
import Text.Pandoc
import Text.Pandoc.Walk
import Text.Pandoc.Builder
import Text.Pandoc.Highlighting (Style, haddock, styleToCss)

import qualified Data.Text as T
import qualified Data.Text.Slugger as Slugger

--------------------------------------------------------------------------------
-- CONFIG

root :: String
root =
  "https://japiirainen.xyz"

siteName :: String
siteName =
  "japiirainen"

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs"
    , ignoreFile = const False
    , previewHost = "127.0.0.1"
    , previewPort = 8000
    , providerDirectory = "."
    , storeDirectory = "_cache"
    , tmpDirectory = "_tmp"
    , watchIgnore = ("_agda/**" ?==)
    }

--------------------------------------------------------------------------------
-- BUILD

main :: IO ()
main = do
  processAgdaPosts
  hakyllWith config $ do
    forM_
      [ "CNAME"
      , "favicon.ico"
      , "robots.txt"
      , "_config.yml"
      , "images/*"
      , "js/*"
      , "fonts/*"
      ]
      $ \f -> match f $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    match (agdaPattern "*.css") $ do
      route agdaRoute
      compile compressCssCompiler

    match (agdaPattern "*.html") $ do
      route agdaRoute
      compile copyFileCompiler

    match (agdaPattern "*.md") $ do
      let ctx = constField "type" "article" <> postCtx

      route $ (metadataRoute titleRoute `composeRoutes` agdaRoute)
      compile $
        pandocCompilerCustom
          >>= loadAndApplyTemplate "templates/post.html" ctx
          >>= saveSnapshot "content"
          >>= loadAndApplyTemplate "templates/default.html" ctx

    match "posts/*" $ do
      let ctx = constField "type" "article" <> postCtx

      route $ metadataRoute titleRoute
      compile $
        pandocCompilerCustom
          >>= loadAndApplyTemplate "templates/post.html" ctx
          >>= saveSnapshot "content"
          >>= loadAndApplyTemplate "templates/default.html" ctx

    match "index.html" $ do
      route idRoute
      compile $ do
        plainPosts <- loadAll "posts/*"
        agdaPosts <- loadAll $ fromString (agdaOutputDir </> "*.md")
        posts <- recentFirst (plainPosts ++ agdaPosts)

        let indexCtx =
              listField "posts" postCtx (return posts)
                <> constField "root" root
                <> constField "siteName" siteName
                <> defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx

    match "templates/*" $
      compile templateBodyCompiler

    match "agda-posts/*.lagda.md" $
      compile $ do
        ident <- getUnderlying
        unsafeCompiler $
          processAgdaPost $
            takeFileName $
              toFilePath ident
        makeItem (mempty :: String)

    create ["sitemap.xml"] $ do
      route idRoute
      compile $ do
        plainPosts <- loadAll "posts/*"
        agdaPosts <- loadAll $ fromString (agdaOutputDir </> "*.md")
        posts <- recentFirst (plainPosts ++ agdaPosts)

        let pages = posts
            sitemapCtx =
              constField "root" root
                <> constField "siteName" siteName
                <> listField "pages" postCtx (return pages)

        makeItem ("" :: String)
          >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

    create ["rss.xml"] $ do
      route idRoute
      compile (feedCompiler renderRss)

    create ["atom.xml"] $ do
      route idRoute
      compile (feedCompiler renderAtom)

    create ["css/code.css"] $ do
      route idRoute
      compile (makeStyle pandocHighlightStyle)


--------------------------------------------------------------------------------
-- COMPILER HELPERS

makeStyle :: Style -> Compiler (Item String)
makeStyle =
  makeItem . compressCss . styleToCss

--------------------------------------------------------------------------------
-- CONTEXT

feedCtx :: Context String
feedCtx =
  titleCtx
    <> postCtx
    <> bodyField "description"

postCtx :: Context String
postCtx =
  constField "root" root
    <> constField "siteName" siteName
    <> dateField "date" "%Y-%m-%d"
    <> defaultContext

titleCtx :: Context String
titleCtx =
  field "title" updatedTitle

--------------------------------------------------------------------------------
-- TITLE HELPERS

replaceAmp :: String -> String
replaceAmp =
  replaceAll "&" (const "&amp;")

replaceTitleAmp :: Metadata -> String
replaceTitleAmp =
  replaceAmp . safeTitle

safeTitle :: Metadata -> String
safeTitle =
  fromMaybe "no title" . lookupString "title"

updatedTitle :: Item a -> Compiler String
updatedTitle =
  fmap replaceTitleAmp . getMetadata . itemIdentifier

--------------------------------------------------------------------------------
-- PANDOC

pandocCompilerCustom :: Compiler (Item String)
pandocCompilerCustom =
  let mathExtensions =
        extensionsFromList
          [ Ext_tex_math_dollars
          , Ext_tex_math_double_backslash
          , Ext_latex_macros
          , Ext_fenced_code_attributes
          , Ext_gfm_auto_identifiers
          , Ext_implicit_header_references
          , Ext_smart
          , Ext_footnotes
          ]
      writerOptions =
        defaultHakyllWriterOptions
          { writerExtensions =
              writerExtensions
                defaultHakyllWriterOptions
                <> mathExtensions
          , writerHTMLMathMethod = MathJax ""
          , writerHighlightStyle = Just pandocHighlightStyle
          }
   in pandocCompilerWithTransform
        defaultHakyllReaderOptions
        writerOptions
        $ walk prependAnchor
  where
    prependAnchor :: Block -> Block
    prependAnchor (Header lvl attr@(id', _, _) txts) =
      Header
        lvl
        attr
        ( toList
            ( linkWith
                (mempty, ["anchor fas fa-xs fa-link"], mempty)
                ("#" <> id')
                mempty
                mempty
            )
            <> txts
        )
    prependAnchor x = x


pandocHighlightStyle :: Style
pandocHighlightStyle =
  haddock -- https://hackage.haskell.org/package/pandoc/docs/Text-Pandoc-Highlighting.html

-- FEEDS

type FeedRenderer =
  FeedConfiguration ->
  Context String ->
  [Item String] ->
  Compiler (Item String)

feedCompiler :: FeedRenderer -> Compiler (Item String)
feedCompiler renderer =
  renderer feedConfiguration feedCtx
    =<< recentFirst
    =<< loadAllSnapshots "posts/*" "content"

feedConfiguration :: FeedConfiguration
feedConfiguration =
  FeedConfiguration
    { feedTitle = "japiirainen"
    , feedDescription = "My personal website + blog"
    , feedAuthorName = "Joona Piirainen"
    , feedAuthorEmail = "joona.piirainen@gmail.com"
    , feedRoot = root
    }

--------------------------------------------------------------------------------
-- CUSTOM ROUTE

getTitleFromMeta :: Metadata -> String
getTitleFromMeta =
  fromMaybe "no title" . lookupString "title"

fileNameFromTitle :: Metadata -> FilePath
fileNameFromTitle =
  T.unpack . (`T.append` ".html") . Slugger.toSlug . T.pack . getTitleFromMeta

titleRoute :: Metadata -> Routes
titleRoute =
  constRoute . fileNameFromTitle

--------------------------------------------------------------------------------
-- AGDA

agdaCommand :: String
agdaCommand = "agda"

agdaInputDir :: String
agdaInputDir = "agda-posts"

agdaOutputDir :: String
agdaOutputDir = "_agda"

agdaOptions :: String -> [String]
agdaOptions fileName =
  [ "--html"
  , "--html-highlight=auto"
  , "--html-dir=" ++ agdaOutputDir
  , "-i" ++ agdaInputDir
  , agdaInputDir </> fileName
  ]

processAgdaPosts :: IO ()
processAgdaPosts = do
  files <- listDirectory agdaInputDir
  let agdaFiles = filter (".lagda.md" `isSuffixOf`) files
  forM_ agdaFiles processAgdaPost

processAgdaPost :: FilePath -> IO ()
processAgdaPost agdaFile = do
  exitCode <-
    readProcessWithExitCode
      agdaCommand
      (agdaOptions agdaFile)
      mempty
  case exitCode of
    (ExitFailure _, err, _) -> do
      putStrLn $ "Failed to process " ++ agdaFile
      putStrLn err
    (ExitSuccess, out, _) ->
      putStrLn out

agdaPattern :: IsString a => FilePath -> a
agdaPattern ending = fromString $ agdaOutputDir </> ending

agdaRoute :: Routes
agdaRoute = gsubRoute (agdaOutputDir </> "") (const ".")