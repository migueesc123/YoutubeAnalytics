// Use this file to write queries to test your data connector
let
    result = YoutubeAnalytics.VideoStats  ( #date(2017,6,1), #date(2017,6,8) )
in
result
