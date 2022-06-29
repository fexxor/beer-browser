module Tests exposing (..)

import Expect
import Main exposing (Msg(..))
import Set
import Test exposing (..)


all : Test
all =
    describe "Test suite for testing parts of the update functionality"
        [ test "Update with SearchQueryChanged message should not prompt a HTTP call when search query only consists of white-space" <|
            \_ ->
                let
                    model =
                        Tuple.first Main.init
                in
                Expect.equal
                    (model
                        |> Main.update (SearchQueryChanged "  ")
                        |> Tuple.second
                    )
                    Cmd.none
        , test "Update with GotBeerQueryResult message should result in a reset expandedBeerDescriptions" <|
            \_ ->
                let
                    model =
                        Main.init
                            |> Tuple.first
                            |> Main.update (BeerDetailsClicked 123)
                            |> Tuple.first
                in
                Expect.equal
                    (model
                        |> Main.update (GotBeerQueryResult (Ok []))
                        |> Tuple.first
                        |> .expandedBeerDescriptions
                    )
                    Set.empty
        , test "Update with PreviousPageButtonClicked message when page index is 1 should result in page index 1" <|
            \_ ->
                let
                    model =
                        Tuple.first Main.init
                in
                Expect.equal
                    ({ model | pageIndex = 1 }
                        |> Main.update PreviousPageButtonClicked
                        |> Tuple.first
                        |> .pageIndex
                    )
                    1
        ]
