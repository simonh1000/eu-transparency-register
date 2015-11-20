module Register (Model, Action(Activate), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import String exposing (split)
import List exposing (filter, foldl, map)

import History
import Task exposing (Task)
import Effects exposing (Effects)

import Filters.Filters as Filters exposing (Action(..))
import Matches.Matches as Matches exposing (Action(..))
import Entries.Entries as Entries exposing (Action(..))

-- MODEL
-- type Display
--     = Filtered
--     | Recent
--
type alias Model =
    { filters : Filters.Model
    , matches : Matches.Model
    , entries : Entries.Model
    -- , display : Display
    , message : String
    }

init : (Model, Effects Action)
init =
    ( { filters = Filters.init
      , matches = Matches.init
      , entries = Entries.init
    --   , display = Filtered
      , message = "Initialising"
      }
    , Effects.none
    )

-- UPDATE

type Action
    -- = GoRecent
    -- | GoRegister (List String)
    -- | UrlParam (List String)     -- duplicative
    = Activate (List String)
    | FilterAction Filters.Action
    | MatchAction Matches.Action
    | EntryAction Entries.Action
    | NoOp (Maybe ())

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Activate params ->
            case params of
                [] ->
                    ( { model | matches <- fst <| Matches.update Matches.SetRegister model.matches }
                    , updateUrl "default" )   -- homepage
                ["recent"] ->
                    let (_, newEffects) =
                        Matches.update Matches.GetRecents model.matches
                    in ( model
                       , Effects.batch
                            [ Effects.map MatchAction newEffects
                            , updateUrl "recent"
                            ]
                       )
                ids ->
                    let
                        go : String -> (Entries.Model, List (Effects Entries.Action)) -> (Entries.Model, List (Effects Entries.Action))
                        go id_ (model, effects) =
                            let (newM, newE) = Entries.update (GetEntryFor id_) model
                            in  (newM, newE :: effects)

                        (newEntriesModel, effects) = foldl go (model.entries, [ Entries.updateUrl [""] ]) ids
                    in
                        ( { model | entries <- newEntriesModel }
                        , Effects.batch <| map (Effects.map EntryAction) effects
                        )
        FilterAction (GetMatch searchModel) ->              -- redirect on search
            let (newMatchesModel, newMatchesEffects) = Matches.update (GetMatchFor searchModel) model.matches
            in  ( { model | matches <- newMatchesModel }
                , Effects.map MatchAction newMatchesEffects
                )
        FilterAction filterAction ->
                ( { model | filters <- Filters.update filterAction model.filters }
                , Effects.none
                )

        MatchAction (GetEntry id) ->                        -- redirect click on a match
            let (newEntriesModel, newEntriesEffects) = Entries.update (GetEntryFor id) model.entries
            in  ( { model | entries <- newEntriesModel }
                , Effects.map EntryAction newEntriesEffects
                )
        MatchAction matchAction ->
            let (newMatchesModel, newMatchEffects) = Matches.update matchAction model.matches
            in  ( { model | matches <- newMatchesModel }
                , Effects.map MatchAction newMatchEffects
                )

        EntryAction entryAction ->
            let (newEntriesModel, newEntriesEffects) = Entries.update entryAction model.entries
            in  ( { model | entries <- newEntriesModel }
                , Effects.map EntryAction newEntriesEffects
                )
        NoOp _ -> ( model, Effects.none )
        -- UrlParam ["recent"] ->
        --     let (newModel, newEffects) =
        --         Matches.update Matches.GetRecents model.matches
        --     in ( { model |
        --            matches <- newModel }
        --        , Effects.map MatchAction newEffects
        --        )
        -- UrlParam ids ->
        --     let
        --         go : String -> (Entries.Model, List (Effects Entries.Action)) -> (Entries.Model, List (Effects Entries.Action))
        --         go id_ (model, effects) =
        --             let (newM, newE) = Entries.update (GetEntryFor id_) model
        --             in  (newM, newE :: effects)
        --
        --         (newEntriesModel, effects) = foldl go (model.entries, [ Entries.updateUrl [""] ]) ids
        --     in
        --         ( { model | entries <- newEntriesModel }
        --         , Effects.batch <| map (Effects.map EntryAction) effects
        --         )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "register" ]
        [ div [ class "row" ]
            [ Filters.view (Signal.forwardTo address FilterAction) model.filters ]
        , div [ class "main row" ]
            [ Matches.view (Signal.forwardTo address MatchAction) model.matches
            , Entries.view (Signal.forwardTo address EntryAction) model.entries
            ]
        -- , p [] [ text model.message ]
        ]

-- INPUTS / TASKS / EFFECTS

updateUrl : String -> Effects Action
updateUrl displayed =
    History.replacePath displayed
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task
