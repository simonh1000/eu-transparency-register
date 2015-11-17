module Common (errorHandler) where

import Http

errorHandler : Http.Error -> String
errorHandler err =
    case err of
        Http.UnexpectedPayload s -> s
        otherwise -> "http error"
