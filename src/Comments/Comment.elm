module Comments.Comment (Model, view, commentsDecoder) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href, style)
-- import Html.Events exposing (onClick, on, targetValue)

import Json.Decode as Json exposing ((:=), list, string, object2)

-- MODEL

type alias Model =
    { comment : String
    -- , email : String
    , date : String
    }

-- init : Model
-- init =
--     Model "" "" ""
--
-- UPDATE

-- type Action
--
-- update : Action -> Model -> (Model, Effects Action)
-- update action model =

-- VIEW

view : Model -> Html
view model =
    div [ class "comment" ]
        [ p []
            [ text model.comment
            , span []
                [ text <| " (" ++ model.date ++ ")"]
            ]
        ]

commentDecoder =
    object2
        Model
        -- ("email" := string)
        ("comment" := string)
        ("date" := string)

commentsDecoder = list commentDecoder
