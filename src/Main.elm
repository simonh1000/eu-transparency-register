module EURegister (main) where

import StartApp

import Effects exposing (Never)
import Task
import Window

import App exposing (init, update, view, Action(UrlParam, Width))
import Summary.Summary as Summary

app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs =
        [ Signal.map UrlParam locationSearch
        , Signal.map Width Window.width
        ]
    }

main =
    app.html

port tasks : Signal (Task.Task Never ())
port tasks =
    app.tasks

port locationSearch : Signal String
