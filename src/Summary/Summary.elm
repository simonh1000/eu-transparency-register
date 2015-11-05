module Summary.Summary (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick, on, targetValue)

import List exposing (foldl)
import Json.Decode exposing (Decoder, list, (:=), string, int, float, object2, object3)

import Http
import Effects exposing (Effects)
import Time exposing (Time)
import Task
import History

import Chart exposing (hBar, pie, title, colours, toHtml, updateStyles)

-- MODEL
type SectionMeasure =
      Count
    | Budget

type alias Interest =
    { interest: String
    , count: Int
    }

type alias Section =
    { section : String
    , count : Float
    , budget: Float
    }

type alias Model =
    { summary : List Interest
    , sections : List Section
    , sectionsSimplified : List Section
    , sectionMeasure : SectionMeasure
    , msg : String
    }

initInterest i c =
    { interest = i
    , count = c
    }
initSection i c b =
    { section = i
    , count = c
    , budget = b
    }

init =
    ( { summary = []
      , sections = []
      , sectionsSimplified = []
      , sectionMeasure = Count
      , msg = ""
      }
    , loadData )

-- UPDATE
type Action =
      Activate
    | InterestData (Result Http.Error (List Interest))
    | SectionsData (Result Http.Error (List Section))
    | NoOp (Maybe ())
    | Animate
    | Tick Time

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Activate ->
            (model, loadData)
        InterestData (Result.Ok data) ->
            ( { model | summary <- data }, updateUrl )
        SectionsData (Result.Ok data) ->
            let
                totalBudget = List.sum (List.map .budget data)
                totalCount = List.sum (List.map .count data)

                -- if budget is significant fraction of total include as is, otherwise as to 'others'
                go : Section -> (Float, Float, List Section) -> (Float, Float, List Section)
                go elem (accBudget, accCount, accS) =
                    let
                        normCount = elem.count / totalCount
                        normBudget = elem.budget / totalBudget
                    in
                    if normBudget < 0.03
                        then (accBudget + normBudget, accCount + normCount, accS)
                        else
                            ( accBudget
                            , accCount
                            , { elem | count <- normCount, budget <- normBudget } :: accS
                            )
                (othersBudget, othersCount, sections) =
                    foldl go (0, 0, []) data
                simplifiedModel =
                    sections ++ [{section = "others", count = othersCount, budget = othersBudget }]
            in
            ( { model | sections <- data, sectionsSimplified <- simplifiedModel }
            , updateUrl )
        SectionsData (Result.Err msg) ->
            ( { model | msg <- errorHandler msg }, updateUrl )
        -- URL  U P D A T E S
        NoOp _ -> ( model, Effects.none )
        Animate ->
            ( { model | sectionMeasure <- if model.sectionMeasure == Count then Budget else Count }
            , Effects.none
            )
        --     let
        --     -- create a set of animations
        --         animations = List.map (\e -> animation 0 |> from )
        --     -- call for first Tick
        -- Tick time ->
        --     -- advance animations
        --     -- call next Tick (unless finished?)

errorHandler : Http.Error -> String
errorHandler err =
    case err of
        Http.UnexpectedPayload s -> s
        otherwise -> "http error"

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let
        countModel = List.map .count model.sectionsSimplified
        budgetModel = List.map .budget model.sectionsSimplified
        labels = List.map .section model.sectionsSimplified
    in
    div [ id "summary", class "row" ]
        [ div [ class "col-xs-12" ]
            [ -- hBar
                -- (List.map (toFloat << .count) sorted)
                -- (List.map .interest sorted)
                -- |> Chart.title "Number of registrants expressing interest in subject"
                -- |> updateStyles "container" [("border","none")]
                -- |> toHtml
            button [ onClick address Animate ] [ text "start" ]
            , pie
                (if model.sectionMeasure == Count then countModel else budgetModel)
                labels
                |> title "Number of registrees per Register sub-section"
                |> colours
                    [ "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
                    , "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
                    , "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
                    ]
                |> toHtml
            -- , pie
            --     budgetModel
            --     labels
            --     |> title "Lobby spend per Register sub-section"
            --     |> colours
            --         [ "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
            --         , "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
            --         , "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
            --         ]
            --     |> toHtml
            , p [] [ text model.msg ]
            ]
        ]

-- TASKS

loadData : Effects Action
loadData =
    -- Http.get issueDecoder ("/api/register/interests")
    Http.get sectionsDecoder ("/api/register/sections")
        |> Task.toResult
        -- |> Task.map InterestData
        |> Task.map SectionsData
        |> Effects.task

issueDecoder : Decoder (List Interest)
issueDecoder =
    object2
        initInterest
        ("issue" := string)
        ("count" := int)
    |> list

sectionsDecoder : Decoder (List Section)
sectionsDecoder =
    object3
        initSection
        ("_id" := string)
        ("count" := float)
        ("total" := float)
    |> list

updateUrl : Effects Action
updateUrl =
    History.replacePath "/summary"
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task
