module Router (Ids, Page(..), Action(..), update, toString) where

import Effects exposing (Effects)
import List exposing (filter, head, foldl, intersperse)
import String exposing (split)
import History
import Task

-- MODEL

type alias Ids = Maybe (List String)      -- empty or with results

type Page
    = Register Ids
    | Summary

toString : Page -> String
toString p =
    case p of
        Register _ -> "register"
        Summary -> "summary"

-- UPDATE

type Action
    = UrlParams String
    | NavAction Page
    | NoOp (Maybe ())

-- update : Action -> Model -> (Model, Effects Action)
update : Action -> (Page, Effects Action)
update action =
    case action of
        UrlParams str ->      -- no need to update URL, by definition
            let
                params =
                    filter ((/=) "") (split "/" str)
                page =
                    case head params of
                        Just "summary" ->
                            Summary
                        Just "recent" ->
                            Register (Just ["recent"])
                        Just _ ->
                            Register (Just params)
                        Nothing ->
                            Register Nothing
            in (page, Effects.none)

        NavAction page ->
            case page of
                Summary ->
                    (Summary, updateUrl "/summary")
                Register ids ->
                    let
                        newUrl = case ids of
                            Just ["recent"] -> "/recent"
                            Just entries -> combineIds entries
                            Nothing -> "/"
                    in (Register ids, updateUrl newUrl)

        NoOp _ ->
            (Register Nothing, Effects.none)   -- unused

-- INPUTS / TASKS / EFFECTS

updateUrl : String -> Effects Action
updateUrl displayed =
    History.replacePath displayed
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task

-- [x,y,z] --> /x/y/z
combineIds : List String -> String
combineIds lst =
    foldl (\l acc -> acc ++ l) "/" (intersperse "/" lst)
