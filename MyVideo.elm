module MyVideo exposing (..)

import Html exposing (..)
import Html.Attributes
    exposing
        ( attribute
        , class
        , src
        , width
        , height
        , type_
        , value
        )
import Html.Events exposing (on, onClick, onInput)

import Http
import Json.Decode exposing (Decoder, string, array)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode exposing (encode, bool)

import Array exposing (..)
import List



-- MODEL

type alias Model =
        { label : String
        , videos : Array VidInfo
        , selected : Int
        , status : String
        , autoplay : Bool
        , autoadvance : Bool
        }

-- For now we only allow some pretty basic customization
type alias VidInfo =
    { title : String, url : String }

init : String -> Bool -> Model
init label autoadvance =
    { label = label
    , videos = empty
    , selected = 0
    , status = "Initialized"
    -- autoplay setting only matters on initial load, so only bother setting
    -- when switching to a new video
    , autoplay = False
    , autoadvance = autoadvance
    }



-- Messages

type Msg
    = NewVidInfo (Result Http.Error (Array VidInfo))
    | SetVidNum Int
    | SetVidNumStr String
    | AdvanceVid

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Currently unused (for button usage)
        SetVidNum num ->
            -- Currently, *I* know this should always be valid, but the
            -- compiler doesn't...
            -- When we switch manually, we wait for user to hit play
            ( { model | selected = num
                      , autoplay = False
               }
            , Cmd.none )

        SetVidNumStr str ->
            let num =
              String.toInt str
            in
              case num of
                Ok val ->
                    ( { model | selected = val
                              , autoplay = False
                       }
                    , Cmd.none )

                -- This should never happen, but the compiler doesn't know that
                Err message ->
                    ( model, Cmd.none )

        AdvanceVid ->
            -- Again, the compiler won't know this is a valid index
            -- When we are in flow, we start the video playing automatically
            if model.autoadvance &&
               (model.selected < (length model.videos - 1)) then
                ( { model | selected = model.selected + 1
                          , autoplay = True }
                , Cmd.none )
            else
                ( model, Cmd.none )

        NewVidInfo (Ok jsonData) ->
            ( { model | videos = jsonData
              , status = "Updated"
              }
            , Cmd.none
            )

        NewVidInfo (Err msg) ->
            ( { model | status = toString msg }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
    case model.status of
        "Updated" ->
            div [] (List.concat
             [ [text (model.label ++ ": ")]
             -- Dropdown
             , [select [ onInput SetVidNumStr ]
                 (List.map (\num -> vidOption num model)
                 (List.range 0 ((length model.videos) - 1)) )]
             -- actual video
            -- XXX need logic here to check for file vs. IFrame
             , videoFile model
             ])

        _ ->
            div [] [text model.status]


-- Currently unused
numButton : Int -> Html Msg
numButton num =
    button [ onClick (SetVidNum (num - 1)) ]
           [ text (toString num) ]

vidOption : Int -> Model -> Html Msg
vidOption num model =
  case get num model.videos of
    Just vid ->
        option (List.concat [ [ value (toString num) ]
                            , (if num == model.selected then
                                   [attribute "selected" ""]
                               else
                                   []) ])
               [ text (toString vid.title) ]

    Nothing ->
        option [ value "1" ] [ text "No Video" ]


videoIFrame : Maybe VidInfo -> List (Html Msg)
videoIFrame maybe_info =
    case maybe_info of
        Nothing ->
            [ text "No (valid) video number selected" ]

        Just info ->
            [ h2 [] [ text info.title ]
            , div [ class "videoWrapper" ]
                [ iframe
                    [ src info.url
                    , width 500
                    , height 282
                    , attribute "frameborder" "0"
                    , attribute "webkitallowfullscreen" ""
                    , attribute "mozallowfullscreen" ""
                    , attribute "allowfullscreen" ""
                    ]
                    []
                ]
            ]

-- per https://www.sitepoint.com/essential-audio-and-video-events-for-html5/
-- Firefox and Chrome (only two I care about) fire "pause" then "ended"
-- at video's end
-- General pattern for briefly stated event handlers
onEnded msg =
  on "ended" (Json.Decode.succeed msg)

maybeAutoplay aYep =
    if aYep then
        [ attribute "autoplay" "" ]
    else
        []

videoFile : Model -> List (Html Msg)
videoFile model =
    let
        maybe_info = get model.selected model.videos

    in
        case maybe_info of
            Nothing ->
                [ text "No (valid) video number selected" ]

            Just info ->
                [ h2 [] [ text info.title ]
                -- These assets are only hosted on DreamHost currently
                , video
                  (List.append
                      [ src info.url
                      , attribute "controls" ""
                      -- The width built-in expects a number
                      , attribute "width" "100%"
                      , onEnded AdvanceVid
                      ]
                      (maybeAutoplay model.autoplay)
                  )
                  [
                     -- This approach messes up autoplay?
                     --  source
                     -- [ attribute "src" info.url
                     -- , type_ "video/mp4"
                     -- ]
                     -- []
                  ]
                ]

-- HTTP

decodeSession : Decoder (Array VidInfo)
decodeSession =
    array
        (decode VidInfo
            |> required "title" string
            |> required "url" string
        )


getClassInfo : String -> Cmd Msg
getClassInfo session =
    let
        url =
            "/class_info/" ++ session ++ ".json"
    in
        Http.send NewVidInfo (Http.get url decodeSession )
