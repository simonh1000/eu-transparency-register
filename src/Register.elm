module Register (Model, Action(Activate, EntriesAction), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import String exposing (split)
import List exposing (filter, foldl, map, length)

import History
import Task exposing (Task)
import Effects exposing (Effects)

import Filters.Filters as Filters exposing (Action(GetMatch))
import Matches.Matches as Matches exposing (Action(..))
import Entries.Entries as Entries exposing (Action(..))
import Router exposing (Ids)
import Help

-- MODEL

type alias Model =
    { filters : Filters.Model
    , matches : Matches.Model
    , entries : Entries.Model
    , message : String
    }

init : (Model, Effects Action)
init =
    ( { filters = Filters.init
      , matches = Matches.init
      , entries = Entries.init
      , message = ""
      }
    , Effects.none
    )

-- UPDATE

type Action
    = Activate Ids      -- Maybe (List String)
    | FilterAction Filters.Action
    | MatchAction Matches.Action
    | EntriesAction Entries.Action
    | Intro Help.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Activate params ->
            case params of
                Just ["recent"] ->
                    let
                        (newModel, newEffects) =
                            Matches.update Matches.GetRecents model.matches
                    in ( { model | matches = newModel }  -- changes to DisplayView and message
                       , Effects.map MatchAction newEffects
                       )
                Just ids ->
                    let
                        -- entries = model.entries
                        -- entriesWithIdsInserted = { entries | displayed = ids }

                        go : String -> (Entries.Model, List (Effects Entries.Action)) -> (Entries.Model, List (Effects Entries.Action))
                        go id_ (model, effects) =
                            let (newM, newE) = Entries.update (GetEntryFor id_) model
                            in  (newM, newE :: effects)

                        (newEntriesModel, effects) =
                            foldl go (model.entries, []) ids

                        matches = fst <| Matches.update Matches.SetFilters model.matches
                    in
                        ( { model
                            | entries = newEntriesModel
                            , matches = matches
                          }
                        , Effects.batch <| map (Effects.map EntriesAction) effects
                        )
                otherwise ->   -- Nothing or []
                    ( { model | matches = fst <| Matches.update Matches.SetFilters model.matches }
                    , Effects.none
                    )

        FilterAction (GetMatch searchModel) ->              -- redirect on search
            let (newMatchesModel, newMatchesEffects) = Matches.update (GetMatchFor searchModel) model.matches
            in  ( { model | matches = newMatchesModel }
                , Effects.map MatchAction newMatchesEffects
                )
        FilterAction filterAction ->
                ( { model | filters = Filters.update filterAction model.filters }
                , Effects.none
                )

        MatchAction (GetEntry id) ->                        -- redirect click on a match
            let (newEntriesModel, newEntriesEffects) =
                Entries.update (GetEntryFor id) model.entries
            in  ( { model | entries = newEntriesModel }
                , Effects.map EntriesAction newEntriesEffects
                )
        MatchAction matchAction ->
            let (newMatchesModel, newMatchEffects) = Matches.update matchAction model.matches
            in  ( { model | matches = newMatchesModel }
                , Effects.map MatchAction newMatchEffects
                )

        EntriesAction entryAction ->
            let (newEntriesModel, newEntriesEffects) = Entries.update entryAction model.entries
            in  ( { model | entries = newEntriesModel }
                , Effects.map EntriesAction newEntriesEffects
                )
        Intro _ -> (model, Effects.none)

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "register" ]
        [ p [ class "error" ] [ text model.message ]
        , div [ class "row" ]
            [ Filters.view (Signal.forwardTo address FilterAction) model.filters ]
        , (mainElement address model)
        ]


mainElement address model =
    if
           ((length model.matches.matches > 0) && (model.matches.display == Matches.Filtered))
        || ((length model.matches.newstuff.entries > 0) && (model.matches.display == Matches.Recents))
        ||  (length model.entries.displayed > 0)
    then
        div
            [ class "main row" ]
            [ Matches.view (Signal.forwardTo address MatchAction) model.matches
            , Entries.view (Signal.forwardTo address EntriesAction) model.entries
            ]
    else
        div
            [ class "main row intro" ]
            [ Help.content ]

--     if model.page == Summary
--         then Summary.view (Signal.forwardTo address SummaryAction) model.summary
--         else Register.view (Signal.forwardTo address RegisterAction) model.register
