module Main exposing (..)

import Browser
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Http
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)



---- CONSTANTS ----


minimumPageIndex : Int
minimumPageIndex =
    -- Could be nice with a custom type that can only be between 1 and n.
    1


pageSize : Int
pageSize =
    10



---- MODEL ----


type alias Model =
    { queryString : String
    , queryResult : QueryResult (List Beer)
    , expandedBeerDescriptions : Set BeerId
    , pageIndex : Int
    }


type QueryResult a
    = QueryNotSent
    | Loading
    | Success a
    | Failure String


type alias BeerId =
    Int


type alias Beer =
    { id : BeerId
    , name : String
    , alcoholByVolume : Float
    , description : String
    , foodPairing : List String
    }


init : ( Model, Cmd Msg )
init =
    ( { queryString = ""
      , queryResult = QueryNotSent
      , expandedBeerDescriptions = Set.empty
      , pageIndex = 1
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = SearchQueryChanged String
    | GotBeerQueryResult (Result Http.Error (List Beer))
    | BeerDetailsClicked BeerId
    | NextPageButtonClicked
    | PreviousPageButtonClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchQueryChanged searchQuery ->
            let
                newModel =
                    { model | pageIndex = minimumPageIndex }
            in
            if (String.trim >> String.isEmpty) searchQuery then
                ( { newModel | queryString = searchQuery, queryResult = QueryNotSent }, Cmd.none )

            else
                -- TODO: Debounce and set queryResult to loading. Right now it's a better experience to not have it flickering.
                ( { newModel | queryString = searchQuery }, getBeerQuery searchQuery model.pageIndex )

        GotBeerQueryResult result ->
            case result of
                Ok res ->
                    ( { model | queryResult = Success res, expandedBeerDescriptions = Set.empty }, Cmd.none )

                Err _ ->
                    -- TODO: Proper error handling.
                    ( { model | queryResult = Failure "Something went wrong" }, Cmd.none )

        BeerDetailsClicked beerId ->
            ( { model
                | expandedBeerDescriptions =
                    if Set.member beerId model.expandedBeerDescriptions then
                        Set.remove beerId model.expandedBeerDescriptions

                    else
                        Set.insert beerId model.expandedBeerDescriptions
              }
            , Cmd.none
            )

        NextPageButtonClicked ->
            let
                newPageIndex =
                    model.pageIndex + 1
            in
            ( { model | pageIndex = newPageIndex, queryResult = Loading }, getBeerQuery model.queryString newPageIndex )

        PreviousPageButtonClicked ->
            let
                newPageIndex =
                    if (model.pageIndex - 1) <= minimumPageIndex then
                        minimumPageIndex

                    else
                        model.pageIndex - 1
            in
            ( { model | pageIndex = newPageIndex, queryResult = Loading }, getBeerQuery model.queryString newPageIndex )


getBeerQuery : String -> Int -> Cmd Msg
getBeerQuery queryString pageIndex =
    Http.get
        { url =
            "https://api.punkapi.com/v2/beers"
                ++ "?per_page="
                ++ String.fromInt pageSize
                ++ "&page="
                ++ String.fromInt pageIndex
                ++ "&beer_name="
                ++ queryString
        , expect = Http.expectJson GotBeerQueryResult (Decode.list beerDecoder)
        }


beerDecoder : Decoder Beer
beerDecoder =
    Decode.map5 Beer
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "abv" Decode.float)
        (Decode.field "description" Decode.string)
        (Decode.field "food_pairing" (Decode.list Decode.string))



---- VIEW ----


view : Model -> Element Msg
view model =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Background.color softBlack
        , Font.color softWhite
        , Font.family [ Font.typeface "Roboto Condensed", Font.sansSerif ]
        ]
        (Element.column
            [ Element.width (Element.fill |> Element.maximum 900)
            , Element.height Element.fill

            -- In the future, it would be nice to create some constants for basic styles.
            , Element.spacing 16
            , Element.padding 24
            , Element.centerX
            ]
            [ Element.el [ Font.size 32, Font.color punkIpaBlue ] (Element.text "Brewdog Beer Browser")
            , Element.paragraph [ Font.color punkIpaTeal ] [ Element.text "Search through Brewdog's expansive back catalogue of beer" ]
            , Input.text
                [ Font.color softBlack
                , Element.padding 12
                , Border.rounded 4
                ]
                { onChange = SearchQueryChanged
                , text = model.queryString
                , placeholder = Just (Input.placeholder [] (Element.text "Type the name of the beer you're looking for"))
                , label = Input.labelHidden "Beer browser search field"
                }
            , Element.el
                [ Element.width Element.fill
                , Element.height Element.fill
                , -- Background.uncropped doesn't work great out of the box when the element height changes.
                  -- In the future, use a background image that's not hosted somewhere else.
                  Background.uncropped "https://harrisbev.com/wp-content/uploads/2020/02/brew-dog.png"
                , Element.htmlAttribute (Html.Attributes.style "background-size" "30vmax auto")
                , Element.htmlAttribute (Html.Attributes.style "background-position" "top")
                ]
                (case model.queryResult of
                    QueryNotSent ->
                        Element.none

                    Loading ->
                        -- TODO: Better loading experience.
                        Element.text "Loading..."

                    Success beerList ->
                        Element.column [ Element.spacing 8, Element.width Element.fill ]
                            (List.map (viewBeerRow model.expandedBeerDescriptions) beerList ++ [ viewPaginationButtons model ])

                    Failure errorMessage ->
                        Element.text errorMessage
                )
            ]
        )


viewBeerRow : Set BeerId -> Beer -> Element Msg
viewBeerRow expandedBeerDescriptions beer =
    let
        isExpanded =
            Set.member beer.id expandedBeerDescriptions
    in
    Element.column
        [ Element.width Element.fill
        , Border.solid
        , Border.color softWhite
        , Border.width 1
        , Border.rounded 4
        ]
        [ Input.button [ Element.width Element.fill ]
            { onPress = Just (BeerDetailsClicked beer.id)
            , label =
                Element.row
                    [ Element.padding 12
                    , Element.spacing 4
                    , Element.width Element.fill
                    ]
                    [ Element.paragraph []
                        [ Element.text beer.name
                        , Element.el [ Font.color punkIpaGray ]
                            (Element.text (" (" ++ String.fromFloat beer.alcoholByVolume ++ " %)"))
                        ]
                    , if isExpanded then
                        Element.el [ Element.alignRight, Element.rotate (degrees 180) ] (Element.text "▾")

                      else
                        Element.el [ Element.alignRight ] (Element.text "▾")
                    ]
            }
        , if isExpanded then
            Element.column
                [ Element.padding 16
                , Element.spacing 8
                , Border.solid
                , Border.color softWhite
                , Border.width 1
                , Border.widthEach
                    { bottom = 0
                    , left = 0
                    , right = 0
                    , top = 1
                    }
                , Element.width Element.fill
                ]
                [ Element.column [ Element.spacing 16 ]
                    [ Element.column [ Element.spacing 8 ]
                        [ Element.el [ Font.color punkIpaTeal ] (Element.text "Description")
                        , Element.paragraph [ Font.color punkIpaGray ] [ Element.text beer.description ]
                        ]
                    , Element.column [ Element.spacing 8 ]
                        (Element.el [ Font.color punkIpaTeal ] (Element.text "Food pairings")
                            :: List.map (\pairing -> Element.paragraph [ Font.color punkIpaGray ] [ Element.text ("○ " ++ pairing) ]) beer.foodPairing
                        )
                    ]
                ]

          else
            Element.none
        ]


viewPaginationButtons : Model -> Element Msg
viewPaginationButtons model =
    Element.row
        [ Element.width Element.fill
        , Font.size 16
        , Font.underline
        , Element.paddingXY 0 4
        ]
        [ if model.pageIndex > minimumPageIndex then
            Input.button [ Element.paddingXY 0 4 ] { onPress = Just PreviousPageButtonClicked, label = Element.text "Previous page" }

          else
            Element.none
        , case model.queryResult of
            Success beerList ->
                if List.length beerList == pageSize then
                    Input.button [ Element.paddingXY 0 4, Element.alignRight ] { onPress = Just NextPageButtonClicked, label = Element.text "Next page" }

                else
                    Element.none

            _ ->
                Element.none
        ]


punkIpaTeal : Element.Color
punkIpaTeal =
    Element.rgb255 104 197 215


punkIpaBlue : Element.Color
punkIpaBlue =
    Element.rgb255 1 179 205


punkIpaGray : Element.Color
punkIpaGray =
    Element.rgb255 216 214 213


softWhite : Element.Color
softWhite =
    Element.rgb255 240 240 240


softBlack : Element.Color
softBlack =
    Element.rgb255 15 15 15



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view >> Element.layout []
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
