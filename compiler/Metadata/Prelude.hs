module Metadata.Prelude (interfaces, add) where

import qualified Data.Map as Map
import qualified Control.Exception as E
import qualified Paths_Elm as Path
import System.Directory
import System.Exit
import System.FilePath
import System.IO
import System.IO.Unsafe (unsafePerformIO)
import SourceSyntax.Module
import qualified Data.Binary as Binary
import qualified Data.ByteString.Lazy as BS


add :: Module t v -> Module t v
add (Module name exs ims stmts) = Module name exs (customIms ++ ims) stmts
    where
      customIms = concatMap addModule prelude

      addModule (n, method) = case lookup n ims of
                                Nothing     -> [(n, method)]
                                Just (As m) -> [(n, method)]
                                Just _      -> []

prelude :: [(String, ImportMethod)]
prelude = text ++ map (\n -> (n, Hiding [])) modules
  where
    text = map ((,) "Text") [ As "Text", Hiding ["link", "color", "height"] ]
    modules = [ "Basics", "Signal", "List", "Maybe", "Time", "Prelude"
              , "Graphics.Element", "Color", "Graphics.Collage" ]

{-# NOINLINE interfaces #-}
interfaces :: Interfaces
interfaces =
    unsafePerformIO (safeReadDocs =<< Path.getDataFileName "interfaces.data")

safeReadDocs :: FilePath -> IO Interfaces
safeReadDocs name =
    E.catch (readDocs name) $ \err -> do
      let _ = err :: IOError
      putStrLn $ unlines [ "Error reading types for standard library!"
                         , "    The file should be at " ++ name
                         , "    If you are using a stable version of Elm,"
                         , "    please report an issue at github.com/evancz/Elm"
                         , "    and specify your versions of Elm and your OS" ]
      exitFailure

readDocs :: FilePath -> IO Interfaces
readDocs name = do
  exists <- doesFileExist name
  case exists of
    False -> ioError . userError $ "File Not Found"
    True -> do
      handle <- openBinaryFile name ReadMode
      bits <- BS.hGetContents handle
      let ifaces = Map.fromList (Binary.decode bits)
      BS.length bits `seq` hClose handle
      return ifaces
