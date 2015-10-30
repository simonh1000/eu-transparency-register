module Chart.Chart (chart) where

import Html exposing (..)
import Html.Attributes exposing (class, id, style)

import List exposing (..)

-- API

chart : List Float -> List String -> String -> Html
chart ds ls title =
    chartInit ds ls
        |> chartTitle title
        |> normalise
        |> addValue
        |> toHtml

-- MODEL

type alias Item =
    { value : Float
    , normValue : Float
    , label : String
    }
initItem v l =
    { value = v
    , normValue = 0
    , label = l
    }

type alias Items = List Item
initItems = map2 initItem

type alias Style = (String, String)

type alias Model =
    { items : Items
    , title : String
    , chartStyles : List Style
    , barStyles : List Style
    }

chartInit : List Float -> List String -> Model
chartInit vs ls =
    { items = initItems vs ls
    , title = ""
    , chartStyles =
        [ ( "background-color", "#eee" )
        , ( "padding", "2%" )
        , ( "border", "1px solid #aaa" )
        ]
    , barStyles =
        [ ("background-color", "steelblue")
        , ("font", "10px sans-serif")
        , ("text-align", "right")
        , ("padding", "3px")
        , ("margin", "1px")
        , ("color", "white")
        ]
    }

-- UPDATE

chartTitle : String -> Model -> Model
chartTitle newTitle model =
     { model - title | title = newTitle }

normalise : Model -> Model
normalise model =
    case maximum (map .value model.items) of
        Nothing -> model
        (Just maxD) ->
            { model |
                items <- map (\item -> { item | normValue <- item.value / maxD * 100 }) model.items
            }

addValue : Model -> Model
addValue model =
    { model |
        items <- map (\item -> { item | label <- item.label ++ " " ++ toString item.value }) model.items
    }

-- VIEW

toHtml : Model -> Html
toHtml model =
    div [ style model.chartStyles ] <|
        h3 [] [ text model.title ]
        :: map
            (\{normValue, label} -> div [ style <| ("width", toString normValue ++ "%") :: model.barStyles] [ text label ] )
            model.items
