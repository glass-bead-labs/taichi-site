module Main exposing (..)

import Html exposing (..) -- includes program
import Html.Attributes
    exposing
        ( name
        , style
        , type_
        , src
        , attribute
        , height
        )
import Html.Events exposing (onClick)
import Http

import Array exposing (Array, get, length, empty)

import MyViews exposing (VidInfo, decodeSession, videoFile)

main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { warmup : VidInfo
    , form : Array VidInfo
    , status : String
    , selected : Int
    }


warmup =
    { title = "Taichi warmup"
    , url = "//player.vimeo.com/video/119411037"
    }


init : ( Model, Cmd Msg )
init =
    ( { warmup = warmup
      , form = empty
      , status = "Initialized"
      , selected = 0
      }
    , getClassInfo "current"
    )



-- UPDATE


type Msg
    = NewVidInfo (Result Http.Error (Array VidInfo))
    | SetWeek Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetWeek num ->
            ( { model | selected = num }, Cmd.none )

        NewVidInfo (Ok jsonData) ->
            -- Note we always reset selected to 0 here
            -- Out-of-bounds checking is handled under the view in videoIFrame
            ( { model | form = jsonData, selected = 0, status = "Updated" }
            , Cmd.none
            )

        NewVidInfo (Err msg) ->
            ( { model | status = toString msg }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
    case model.status of
        "Updated" ->
            dispVideos model

        _ ->
            text model.status


dispVideos : Model -> Html Msg
dispVideos model =
    div []
        (List.concat
          [
          -- Warmups
          --   (videoIFrame (Just model.warmup))

          -- Form
          -- , (text "Select week: "
          --     :: List.map weekButton (List.range 1 (length model.form))
          --   )
            (videoFile (get model.selected model.form))
            -- (Just (VidInfo "Week 1: Opening"
            --              ("//taichi.reallygoodmoving.com" ++
            --               "/videos/form/01-opening.mp4") )))
          , journal
          ]
        )


weekButton : Int -> Html Msg
weekButton num =
    button [ onClick (SetWeek (num - 1)) ] [ text (toString num) ]

journal =
    [ h1 [] [ text "Take credit: Journal your practice!"]
      , iframe
        [ src ("https://docs.google.com/forms/d/e/" ++
               "1FAIpQLSeYzzZNa_3IdwqNRqX1ESqlPdkRaDXuPxA5-iE5kkxx5KEdpw" ++
               "/viewform?embedded=true")
        , attribute "width" "100%"
        , height 1700
        , attribute "frameborder" "0"
        , attribute "marginheight" "0"
        ]
        [ text "Loading..." ]
      ]

-- SUBSCRIPTIONS - currently unused


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


getClassInfo : String -> Cmd Msg
getClassInfo session =
    let
        url =
            "/class_info/" ++ session ++ ".json"
    in
        Http.send NewVidInfo (Http.get url decodeSession )



