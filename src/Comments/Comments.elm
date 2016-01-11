module Comments.Comments (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href, style)
import Html.Events exposing (onClick, on, targetValue)
import List

import Http
import Effects exposing (Effects)
import Task exposing (..)

import Comments.Comment as Comment
import Comments.NewComment as NewComment exposing (Action(..), prettyDate)
import Common exposing (errorHandler)

-- MODEL

type alias Model =
    { displayed : Bool
    , comments : List Comment.Model
    , formData : NewComment.Model
    , msg : String
    }

init : (Model, Effects Action)
init =
    ( Model False [] (fst NewComment.init) ""
    , Effects.none
    )

-- UPDATE

type Action
    = Display
    | Comments (Result Http.Error (List Comment.Model))
    | CommentForm NewComment.Action    -- adding new comment

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Display ->
            let gc =
                    if (not model.displayed) && (List.length model.comments == 0)
                        then getComments
                        else Effects.none
            in
            ( { model | displayed = not model.displayed }
            , Effects.batch
                [ Effects.map CommentForm (snd NewComment.init)     -- gets the date
                , gc
                ]
            )

        Comments res ->
            case res of
                Result.Ok coms ->
                    ( { model | comments = coms }, Effects.none )
                Result.Err msg ->
                    ( model, Effects.none )

        CommentForm (PostResult r) ->
            case r of
                Result.Ok _ ->
                    let
                        newComment =
                            Comment.Model
                                model.formData.comment
                                (prettyDate model.formData.date)
                        (newModel, _) = NewComment.update (PostResult r) model.formData
                    in
                    ( { model
                        | comments = newComment :: model.comments
                        , formData = newModel
                      }
                    , Effects.none
                    )
                Result.Err err ->
                    ( { model | msg = errorHandler err }
                    , Effects.none
                    )

        CommentForm act ->
            let (newModel, newEffects) = NewComment.update act model.formData
            in
                ( { model | formData = newModel }
                , Effects.map CommentForm newEffects
                )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "commentsBox" ] <|
        [ p
            [ class "message" ]
            [ text model.msg ]
        , NewComment.view (Signal.forwardTo address CommentForm) model.formData
        -- , h3 [] [ text "Comments received" ]
        , div
            [ class "comments" ] <|
            List.map Comment.view model.comments
        ]

-- TASKS

getComments : Effects Action
getComments =
    Http.get Comment.commentsDecoder ("/api/comments")
        |> Task.toResult
        |> Task.map Comments
        |> Effects.task
