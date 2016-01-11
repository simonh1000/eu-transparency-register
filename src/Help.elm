module Help (Model, Action(Help), init, update, content, view) where

import Html exposing (Html, div)
import Html.Attributes exposing (id, class)
import Markdown

type alias Model = Bool

init : Model
init = True

type Action
    = Help

update : Action -> Model -> Model
update action model =
    case action of
        Help -> not model


content : Html
content =
    Markdown.toHtml """
**TLDR** Use the filters above to explore the Register.

# The European Union (EU) Transparency Register

The [Commission's lobby register](http://ec.europa.eu/transparencyregister/public/homePage.do) is a great move towards transparency, but it has two key functional deficiencies addressed here:

 - **Comparing entries**: What resources is one lobbyist using compared to another?

 - **Sharing links to entries**: Want to discuss with a colleague, or share on social media? You need direct (deep) links.

So, try these examples:

- My [recent employers](/537380918401-76/761346015292-83/03181945560-59/002278013515-26/260243819561-20)
- The [EU Social partners](/06698681039-26/3978240953-79)
- A collection of [Brussel's biggest consultants](/9155503593-86/56047191389-84/7223777790-86/81995781088-41)
- A handful of [NGOs](/11063928073-34/9832909575-41/1414929419-24/16311905144-06/71149477682-53)

I deliberately focus on only some of the Register's freely available data in order to provide a better comparability. (For budget comparisons, I use the specific cost data provided by registrees or the mid-point of the budget range selected.) Contact me via my [blog](https://digitalusers.wordpress.com/2015/10/29/making-the-eu-transparency-register-more-functional/).

**Privacy:** This site uses the Google Analytics cookie.

**Open source** The source code is available at [Github](https://github.com/simonh1000/eu-transparency-register).

"""

-- view : Signal.Address Action -> Model -> Html
-- view address model =
--     if model
--         then
--             div
--                 [ id "intro"
--                 -- , class "container"
--                 ]
--                 [ content
--                 -- , button
--                 --     [ class "btn btn-default"
--                 --     ,  onClick address Help
--                 --     ]
--                 --     [ text "Close" ]
--                 ]
--         else div [] []
-- view : Signal.Address Action -> Model -> Html
view =
    div
        [ id "intro"
        ]
        [ content ]
