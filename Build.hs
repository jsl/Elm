-- This file compiles all library and runtime code 
-- into elm-runtime.js. Run it with following command:
--
--     runHaskell Build.hs
--
-- Note: This does NOT compile the compiler! Run `cabal install`
-- from the compiler/ directory to do that.

import System.Cmd
import System.Directory
import System.Exit
import System.FilePath
import System.IO
import Language.Elm

getFiles ext dir = do
  contents <- map (dir </>) `fmap` getDirectoryContents dir
  let files = filter (\f -> takeExtension f == ext) contents
      dirs  = filter (not . hasExtension) contents
  filess <- mapM (getFiles ext) dirs
  return (files ++ concat filess)
  
appendJS file = do
  putStrLn (dropExtension file)
  str <- readFile file
  length str `seq` return ()
  appendFile "elm-runtime.js" str

appendElm file = do
  system ("elm --only-js " ++ file)
  let jsFile = replaceExtension file ".js"
  appendJS jsFile
  removeFile jsFile

main = do
  writeFile "elm-runtime.js" "Elm = {}; Elm.Native = {}; Elm.Native.Graphics = {}; Elm.Graphics = {};\n"
  mapM_ appendJS  =<< getFiles ".js"  "libraries"
  mapM_ appendElm =<< getFiles ".elm" "libraries"
  mapM_ appendJS  =<< getFiles ".js"  "runtime"
  putStrLn "Success building runtime and libraries!"
  exitSuccess