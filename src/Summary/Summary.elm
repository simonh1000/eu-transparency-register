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

import Chart exposing (hBar, pie, title, colours, toHtml, updateStyles, addValueToLabel)

import Common exposing (errorHandler)
import Summary.SummaryDecoder as Decoder exposing (Summary, Section, Interest, Country)

-- MODEL
type Chart
    = Sections
    | Countries

type ChartType
    = Simple
    | Complex

type alias Model =
    { interests : List Interest
    , sections : List Section
    , countries : List Country
    , sectionChart : ChartType
    , countryChart : ChartType
    , msg : String
    }

init =
    { interests = []
    , sections = []
    , countries = []
    , sectionChart = Simple
    , countryChart = Simple
    , msg = ""
    }

-- UPDATE
type Action
    = Activate
    -- | InterestData (Result Http.Error (List Interest))
    -- | SectionsData (Result Http.Error (List Section))
    -- | CountryData (Result Http.Error (List Country))
    | SummaryData (Result Http.Error Summary)
    | NoOp (Maybe ())
    | Animate Chart
    -- | Tick Time

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Activate ->
            ( model
            , if List.length model.interests == 0
              then loadSummary
              else Effects.none
            )
        SummaryData (Result.Ok summary) ->
            ( { model
                | sections = simplifySectionsData (summary.sections)
                , countries = simplifyCountiesData summary.countries
                , interests = List.sortBy (negate << .count) summary.interests
               }
            -- , Effects.none )    -- History is not updated
            , updateUrl )
        SummaryData (Result.Err msg) ->
            ( { model | msg = errorHandler msg }
            , updateUrl
            -- , Effects.none
            )
        -- URL  U P D A T E S
        NoOp _ -> ( model, Effects.none )
        Animate chart ->
            let
                toggle x = if x == Simple then Complex else Simple

                newModel =
                    case chart of
                        Sections -> { model | sectionChart = toggle model.sectionChart }
                        Countries -> { model | countryChart = toggle model.countryChart }
            in
                ( newModel , Effects.none )

simplifySectionsData : List Section -> List Section
simplifySectionsData data =
    let
        totalBudget = List.sum (List.map .budget data)
        totalCount = List.sum (List.map .count data)

        -- if budget is significant fraction of total include as is, otherwise add to 'others'
        go : Section -> (Float, Float, List Section) -> (Float, Float, List Section)
        go elem (othersBudg, othersCnt, accS) =
            let
                normCount = elem.count / totalCount
                normBudget = elem.budget / totalBudget
            in
            if normBudget < 0.03
                then (othersBudg + normBudget, othersCnt + normCount, accS)
                else
                    ( othersBudg
                    , othersCnt
                    , { elem | count = normCount, budget = normBudget } :: accS
                    )
        (othersBudget, othersCount, sections) =
            foldl go (0, 0, []) data
    in
        (List.sortBy (negate << .count) sections) ++
        [{section = "Others", count = othersCount, budget = othersBudget }]

simplifyCountiesData : List Country -> List Country
simplifyCountiesData data =
    let
        total = List.sum (List.map .count data)

        -- if budget is significant fraction of total include as is, otherwise add to 'others'
        -- go : Country -> (Float, List Country) -> (Float, List Country)
        go elem (othersCnt, othersPass, accS) =
            if (elem.count / total * 100) < 4
                then ( othersCnt + elem.count, othersPass + elem.eppass, accS )        -- add to others
                else ( othersCnt, othersPass, elem :: accS )   -- keep, by coping into accumulatro directly
        (othersCount, othersEPPass, accCountries) =
            foldl go (0, 0, []) data
    in
        (List.sortBy (negate << .count) accCountries) ++
        [{country = "RoW", count = othersCount, eppass = othersEPPass }]

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let
        countModel = List.map .count model.sections
        budgetModel = List.map .budget model.sections
        labels = List.map .section model.sections
    in
    -- Country HQ
    div [ id "summary", class "row" ]
        [ div [ class "col-xs-12" ]
            [ pie
                (if model.countryChart == Simple
                    then List.map .count model.countries
                    else List.map .eppass model.countries)
                (List.map .country model.countries)
                |> title
                    (if model.countryChart == Simple
                        then "No. corporate registrees by HQ Country"
                        else "No. corporate EP accreditations by HQ Country")
                |> addValueToLabel
                |> colours
                    [ "#5DA5DA", "#FAA43A", "#60BD68", "#F17CB0", "#B2912F", "#DECF3F", "#9a9a9a", "#F15854", "#BF69B1", "#4D4D4D"
                    ]
                |> updateStyles "chart-container" [("flex-wrap", "wrap")]
                |> updateStyles "legend" [("max-width", "100%")]
                |> updateStyles "container" [("border","none")]
                |> toHtml
            ]
            , div
                [ class "toggleContainer" ]
                [ button
                    [ onClick address (Animate Countries) ]
                    [ text <| if model.countryChart == Simple
                        then "Switch to EP accreditations"
                        else "Switch to no. registrees"
                    ]
                ]
        , div [ class "col-xs-12" ]
            [ pie
                (if model.sectionChart == Simple then countModel else budgetModel)
                labels
                |> title
                    (if model.sectionChart == Simple
                     then "Number of registrees per sub-section"
                     else "Lobby spend per sub-section"
                    )
                |> colours
                    [ "#5DA5DA", "#FAA43A", "#60BD68", "#F17CB0", "#B2912F", "#B276B2", "#DECF3F", "#F15854", "#BF69B1", "#4D4D4D"
                    --  "#BF69B1", "#96A65B", "#D9A679", "#593F27", "#A63D33"
                    ]
                -- updateStyles String List Chart.Style Chart.Model
                |> updateStyles "chart-container" [("flex-wrap", "wrap")]
                |> updateStyles "legend" [("max-width", "100%")]
                |> updateStyles "container" [("border","none")]
                |> toHtml
            , div
                [ class "toggleContainer" ]
                [ button
                    [ onClick address (Animate Sections) ]
                    [ text <| if model.sectionChart == Simple
                        then "Switch to lobby spend"
                        else "Switch to no. registrees"
                    ]
                ]
            , div
                [ class "interests" ]
                [ hBar                      -- Interests
                    (List.map (toFloat << .count) model.interests)
                    (List.map .interest model.interests)
                    |> Chart.title "Number of registrants expressing interest in subject"
                    |> updateStyles
                        "container"
                        [ ("border", "none")
                        , ("border-top", "3px solid black")
                        ]
                    |> toHtml
                ]
            , p [] [ text model.msg ]
            ]
        ]

-- TASKS

loadSummary : Effects Action
loadSummary =
    Http.get Decoder.summaryDecoder ("/api/register/summary")
        |> Task.toResult
        |> Task.map SummaryData
        |> Effects.task

updateUrl : Effects Action
updateUrl =
    History.replacePath "/summary"
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task
