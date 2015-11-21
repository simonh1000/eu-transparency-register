module Summary.SummaryDecoder (..) where

import Json.Decode as Json exposing (Decoder, list, (:=), string, int, float, object2, object3)

type SummaryInfo
    = Interests (List Interest)
    | Sections (List Section)
    | Countries (List Country)

type alias Interest =
    { interest: String
    , count: Int
    }

type alias Section =
    { section : String
    , count : Float
    , budget: Float
    }

type alias Country =
    { country : String
    , count: Float
    }

type alias Summary =
    { sections : List Section
    , interests : List Interest
    , countries : List Country
    }

initInterest i c =
    { interest = i
    , count = c
    }
initSection i c b =
    { section = i
    , count = c
    , budget = b
    }
initCountry i c =
    { country = i
    , count = c
    }

interestsDecoder : Decoder (List Interest)
interestsDecoder =
    object2
        initInterest
        ("interest" := string)
        ("count" := int)
    |> list

sectionsDecoder : Decoder (List Section)
sectionsDecoder =
    object3
        initSection
        ("_id" := string)
        ("count" := float)
        ("total" := float)
    |> list

countriesDecoder : Decoder (List Country)
countriesDecoder =
    object2
        initCountry
        ("_id" := string)
        ("count" := float)
    |> list

summaryItemDecoder : String -> Decoder SummaryInfo
summaryItemDecoder item =
    let dec =
        case item of
            "sections" -> Json.map Sections sectionsDecoder
            "interests" -> Json.map Interests interestsDecoder
            otherwise -> Json.map Countries countriesDecoder
    in ("data" := dec)

listSummaryDecoder : Decoder (List SummaryInfo)
listSummaryDecoder =
    ("_id" := string) `Json.andThen` summaryItemDecoder
    |> list


summaryDecoder : Decoder Summary
summaryDecoder =
    Json.map combine listSummaryDecoder

emptySummary : Summary
emptySummary =
    { sections = []
    , interests = []
    , countries = []
    }

combine : List SummaryInfo -> Summary
combine lst =
    let
        insert info sum =
            case info of
                Sections ss -> { sum | sections = ss }
                Interests is -> { sum | interests = is }
                Countries cs -> { sum | countries = cs }

    in
    List.foldl insert emptySummary lst
