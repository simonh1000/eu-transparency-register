module Help (content) where

import Markdown
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

type Action = A

content : Signal.Address Action -> Html
content address =
    div
        [ class "help-modal" ]
        [ Markdown.toHtml """

# Notes

This project uses information from the [European Union Transparency Register](http://ec.europa.eu/transparencyregister/public/homePage.do), which is made freely available to third parties under the EU's open data policy. The data on this site is updated frequently with the latest information made avaialble by the Commission.

I have sought to focus on key pieces of information in the Register and to provide a better ability to compare registrees.

In order to provide the budget comparisons, I use the costs data provided by registrees or, if that is not provided, the mid-point of the budget range that was selected.

Please provide feedback via the [blog]() announcing this service.

## Privacy

This site uses the Google Analytics cookie.

## Open source

The code for this site is freely available on [Github](...).

"""
        , button
            [ class "btn btn-default"
            ,  onClick address A
            ] [ text "Close" ]
        ]
