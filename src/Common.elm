module Common (errorHandler, onLinkClick) where

import Http
import Signal
import Json.Decode as Json
import Html.Events exposing (onWithOptions)

errorHandler : Http.Error -> String
errorHandler err =
    case err of
        Http.UnexpectedPayload s -> s
        otherwise -> "http error"

-- onWithOptions : String -> Options -> Decoder a -> (a -> Message) -> Attribute
onLinkClick address act =
    onWithOptions
        "click"
        {stopPropagation=True, preventDefault=True}
        (Json.succeed act)
        (Signal.message address)
