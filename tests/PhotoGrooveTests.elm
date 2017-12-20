module PhotoGrooveTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Test exposing (..)
import PhotoGroove exposing (..)
import Json.Decode exposing (decodeValue)
import Json.Encode as Encode
import Test.Html.Query as Query
import Test.Html.Selector exposing (text, tag, attribute)
import Test.Html.Event as Event


suite : Test
suite =
    -- todo "Implement our first test. See http://package.elm-lang.org/packages/elm-community/elm-test/latest for how to do this!"
    test "one plus one equals two" (\_ -> Expect.equal 2 (1 + 1))


decoderTest : Test
decoderTest =
    test "title defaults to (untitled)" <|
        \_ ->
            """{ "url": "fruits.com", "size": 5 }"""
                |> Json.Decode.decodeString photoDecoder
                |> Result.map .title
                |> Expect.equal (Ok "(untitled)")


decoderFuzzTest : Test
decoderFuzzTest =
    fuzz2 string int "fuzz test for title defaults to (untitled)" <|
        \url size ->
            [ ( "url", Encode.string url )
            , ( "size", Encode.int size )
            ]
                |> Encode.object
                |> decodeValue photoDecoder
                |> Result.map .title
                |> Expect.equal (Ok "(untitled)")


stateTransitions : Test
stateTransitions =
    describe "state transitions"
        [ fuzz string " SelectByUrl selects the given photo by URL " <|
            \url ->
                PhotoGroove.initialModel
                    |> PhotoGroove.update (SelectByUrl url)
                    |> Tuple.first
                    |> .selectedUrl
                    |> Expect.equal (Just url)
        , fuzz (list string) "LoadPhotos selects the first photo" <|
            \urls ->
                let
                    photos =
                        List.map photoFromUrl urls
                in
                    PhotoGroove.initialModel
                        |> PhotoGroove.update (LoadPhotos (Ok photos))
                        |> Tuple.first
                        |> .selectedUrl
                        |> Expect.equal (List.head urls)
        ]


photoFromUrl : String -> Photo
photoFromUrl url =
    { url = url, size = 0, title = "" }


noPhotosNoThumbnails : Test
noPhotosNoThumbnails =
    test "No thumbnails render when there are no photos to render." <|
        \_ ->
            PhotoGroove.initialModel
                |> PhotoGroove.view
                |> Query.fromHtml
                |> Query.findAll [ tag "img" ]
                |> Query.count (Expect.equal 0)



-- thumbnailRendered : String -> Query.Single msg -> Expectation
-- thumbnailRendered url query =
--     query
--         |> Query.findAll [ tag "img", attribute "src" (urlPrefix ++ url) ]
--         |> Query.count (Expect.atLeast 1)
-- thumbnailsWork : Test
-- thumbnailsWork =
--     fuzz urlFuzzer "URLs render as thumbnails" <|
--         \urls ->
--             let
--                 thumbnailChecks : List (Query.Single msg -> Expectation)
--                 thumbnailChecks =
--                     List.map thumbnailRendered urls
--             in
--                 { initialModel | photos = List.map photoFromUrl urls }
--                     |> PhotoGroove.view
--                     |> Query.fromHtml
--                     |> Expect.all thumbnailChecks
-- |> Query.fromHtml


urlFuzzer : Fuzzer (List String)
urlFuzzer =
    Fuzz.intRange 1 5
        |> Fuzz.map urlsFromCount


urlsFromCount : Int -> List String
urlsFromCount urlCount =
    List.range 1 urlCount
        |> List.map (\num -> toString num ++ ".png")
