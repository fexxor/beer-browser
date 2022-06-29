module Tests exposing (..)

import Expect
import Test exposing (..)



-- Failing placeholder test suite


all : Test
all =
    describe "A Test Suite"
        [ test "This test should fail" <|
            \_ ->
                Expect.fail "failed as expected!"
        ]
