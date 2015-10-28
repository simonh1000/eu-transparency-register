module App (Action(UrlParam), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import String exposing (split)
import List exposing (filter)

import Effects exposing (Effects)
import Task exposing (..)

import Filters.Filters as Filters exposing (Action(..))
import Matches.Matches as Matches exposing (Action(..))
import Entries.Entries as Entries exposing (Action(..))
import Help

-- MODEL

type alias Model =
    { filters : Filters.Model
    , matches : Matches.Model
    , entries : Entries.Model
    , message : String
    , help    : Bool
    }

init : (Model, Effects Action)
init =
    ( { filters = Filters.init
      , matches = Matches.init
      , entries = Entries.init
      , message = "Initialising"
      , help = False
      }
    , Effects.none )

-- UPDATE

type Action =
      FilterAction Filters.Action
    | MatchAction Matches.Action
    | EntryAction Entries.Action
    | UrlParam String
    | Help

update : Action -> Model -> (Model, Effects Action)
update action model =
    let
        getEntryEffect id_ =
            Effects.map EntryAction <| snd <| Entries.update (GetEntryFor id_) model.entries
    in
    case action of
        UrlParam str ->
            ( { model | message <- str }
            -- , Effects.none
            -- , Effects.map EntryAction <| snd <| Entries.update (GetEntryFor str) model.entries
            , split "/" str
                |> filter (\x -> x /= "")
                |> List.map getEntryEffect
                |> Effects.batch
            )
        FilterAction (GetMatch searchModel) ->
            ( model
            , Effects.map MatchAction <| snd <| Matches.update (GetMatchFor searchModel) model.matches
            )
        FilterAction filterAction ->
            let
                filters' = Filters.update filterAction model.filters
            in ( { model | filters <- fst filters'}, Effects.none )

        MatchAction (GetEntry id) ->
            ( { model | message <- "get entry for " ++ id }
            , getEntryEffect id
            )
        MatchAction matchAction ->
            let
                matches' = Matches.update matchAction model.matches
            in  ( { model | matches <- fst matches'}
                , Effects.map MatchAction <| snd <| matches'
                )

        EntryAction entryAction ->
            let
                entries' = Entries.update entryAction model.entries
            in  ( { model | entries <- fst entries' }
                , Effects.map EntryAction <| snd <| entries'
                )
        Help ->
            ( { model | help <- not model.help }
            , Effects.none
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let
        help =
            button
                [ class "btn btn-default btn-xs"
                , onClick address Help
                ] [ text "Notes, privacy, source code or report a problem" ]
    in
    div [ class "container" ]
        [ nav [] [ h1 [] [ text "European Lobby Register" ] ]
        , if model.help
            then Help.content (Signal.forwardTo address (\_ -> Help))
            else div [] []
        , Filters.view (Signal.forwardTo address FilterAction) model.filters
        , div [ class "row main" ]
            [ div [ class "col-sm-4" ]
                [ Matches.view (Signal.forwardTo address MatchAction) model.matches ]
            , div [ class "col-sm-8" ]
                [ Entries.view (Signal.forwardTo address EntryAction) model.entries ]
            ]
        , help
        ]
