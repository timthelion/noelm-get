module Get.Registry where

import Control.Exception
import Control.Monad.Error
import Network.HTTP
import Network.Stream

domain = "http://localhost:8000/"

latest :: String -> ErrorT String IO String
latest library =
    request (getRequest $ domain ++ "latest?library=" ++ library) id

versions :: String -> ErrorT String IO String
versions library =
    request (getRequest $ domain ++ "versions?library=" ++ library) id

register :: String -> String -> String -> ErrorT String IO String
register library version docs =
    request (postRequestWithBody url "text/json" docs) id
  where
    url = domain ++ "register?library=" ++ library ++ "&version=" ++ version

request :: Request_String -> (String -> a) -> ErrorT String IO a
request request handler = do
  result <- liftIO $ simpleHTTP request `catch` \err ->
                          let _ = err :: IOException
                          in  return $ failMisc $ "Unable to connect to " ++ domain
  case result of
    Right response
        | rspCode response == (2,0,0) -> return $ handler $ rspBody response
        | otherwise -> throwError $ rspBody response

    Left (ErrorMisc str) -> throwError str
    Left err -> throwError (show err)