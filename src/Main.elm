module Register (main) where

import StartApp

import Effects exposing (Never)
import Task
import History
import Time

import App exposing (init, update, view, Action)

app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs =
        -- [ Signal.map App.UrlParam History.path
        -- [ --Signal.map App.UrlParam (Signal.sampleOn (Time.every 1000) <| Signal.constant locationSearch)
        [ Signal.map App.UrlParam (Signal.sampleOn mythicalSignal locationSearch)
        ]
    }

main =
  app.html

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

port locationSearch : Signal String
port mythicalSignal : Signal String
