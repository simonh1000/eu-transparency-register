module EURegister (main) where

import StartApp

import Effects exposing (Never)
import Task

import App exposing (init, update, view, Action(UrlParam))
import Summary.Summary as Summary

app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = [ Signal.map UrlParam locationSearch ]
    }

main =
    app.html

port tasks : Signal (Task.Task Never ())
port tasks =
    app.tasks

port locationSearch : Signal String
