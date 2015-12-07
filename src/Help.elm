module Help (content) where

import Html exposing (Html)
import Markdown

content : Html
content =
    Markdown.toHtml """

# Notes

This project uses information from the [European Union Transparency Register](http://ec.europa.eu/transparencyregister/public/homePage.do), made publicly available under the EU's open data policy. The data is updated frequently with the latest source from the Commission but cannot guarantee to contain all the latest changes.

I have sought to focus on key pieces of information in the Register and to provide a better ability to compare registrants.

In order to provide the budget comparisons, I use the costs data provided by registrants or, if that is not provided, the mid-point of the budget range selected.

Please provide feedback via the [blog](https://digitalusers.wordpress.com/2015/10/29/making-the-eu-transparency-register-more-functional/) announcing this service.

## Privacy

This site uses the Google Analytics cookie.

## Open source

The source code is available under an open source licence on [Github](https://github.com/simonh1000/eu-transparency-register).

"""
