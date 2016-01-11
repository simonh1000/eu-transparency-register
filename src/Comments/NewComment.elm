module Comments.NewComment (Model, Action(PostResult), init, update, view, prettyDate) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', value, style, required, placeholder)
import Html.Events exposing (on, targetValue, onWithOptions)

import Http

import Task exposing (Task)
import Effects exposing (Effects)
import TaskTutorial exposing (getCurrentTime)
import Date exposing (Date, fromTime)
import Time exposing (Time)
import Json.Decode as Json exposing ((:=))
import Json.Encode as Encode

-- MODEL
type Field
    = Email
    | Comment

type alias Model =
    { comment : String
    , email : String
    , date : Maybe Date
    }

init : (Model, Effects Action)
init =
    (Model "" "" Nothing, getTime)

-- UPDATE

type Action
    = Input Field String
    | CurrentTime (Maybe Time)
    | Submit
    | PostResult (Result Http.Error Bool)   -- will be caught by parent as well

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        CurrentTime t ->
            ( { model | date = Maybe.map fromTime t }, Effects.none )
            -- case t of
            --     Just t' ->
            --         ( { model | date = fromTime t' }, Effects.none )
            --     Nothing ->
            --         ( { model | date = "" }, Effects.none )
        Input field str ->
            case field of
                Email ->
                    ( { model | email = str }, Effects.none)
                Comment ->
                    ( { model | comment = str }, Effects.none)
        Submit ->
            ( model
            , submitPost model
            )
        PostResult r ->
            case r of
                Result.Ok _ ->
                    ( { model | email = "", comment = "" }   -- dont want to delete date
                    , Effects.none
                    )
                Result.Err m ->
                    ( model, Effects.none)
-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ class "commentEntry" ]
        [ form
            [ onSubmit' address Submit ]
            [ div [ class "form-group" ]
                [ label [] [ text "What do you think?*" ]
                , input
                    [ onChange address (Input Comment)
                    , class "form-control"
                    , value model.comment
                    , required True
                    , placeholder "Comment"
                    ]
                    []
                ]
            , div
                [ class "form-inline" ]
                [ div
                    [ class "form-group" ]
                    [ label [] [ text "email (not made public)" ]
                    , input
                        [ onChange address (Input Email)
                        , class "form-control"
                        , value model.email
                        , placeholder "Optional"
                        ]
                        []
                    , button
                        [ type' "submit"
                        , class "btn btn-default" ]
                        [ text "Submit" ]
                    ]
                ]
            ]
            -- , div
            --     [ class "form-group" ]
            --     [ label [] [ text "email (not made public)" ]
            --     , input
            --         [ onChange address (Input Email)
            --         , class "form-control"
            --         , value model.email
            --         ]
            --         []
            --     , button
            --         [ type' "submit"
            --         , class "btn btn-default" ]
            --         [ text "Submit" ]
            --     ]
            -- ]
        ]

-- Signal.message : (Signal.Address a) -> a -> Signal.Message
-- on : String -> Decoder a -> (a -> Message) -> Attribute
onChange address action =
    on "change" (Json.map action targetValue) (Signal.message address)

onSubmit' address action =
    onWithOptions
        "submit"
        {stopPropagation = True, preventDefault = True}
        (Json.succeed action)
        (Signal.message address)

-- TASKS

getTime =
    getCurrentTime
        |> Task.toMaybe
        |> Task.map CurrentTime
        |> Effects.task

prettyDate : Maybe Date -> String
prettyDate date =
    case date of
        Nothing -> ""
        Just d ->
            toString (Date.year d) ++ "-" ++
            toString (Date.month d) ++ "-" ++
            toString (Date.day d)

submitPost : Model -> Effects Action
submitPost model =
    let jsonString =
        Http.string <|
            -- Encode.encode 0 model
            "{\"comment\":\"" ++ model.comment ++ "\",\"email\":\"" ++
            model.email ++ "\",\"date\":\"" ++ prettyDate model.date ++ "\"}"
    in
    post' ("success" := Json.bool) "/api/comments" jsonString
        |> Task.toResult
        |> Task.map PostResult
        |> Effects.task

post' : Json.Decoder a -> String -> Http.Body -> Task Http.Error a
post' dec url body =
    Http.send Http.defaultSettings
    { verb = "POST"
    , headers = [("Content-type", "application/json")]
    -- , headers = [("Content-type", "application/x-www-form-urlencoded")]
    -- , headers = []
    , url = url
    , body = body
    }
        |> Http.fromJson dec
