// Use this file to write queries to test your data connector
let
    result = YoutubeAnalytics.VideoStats  (#date(2017,1,1), #date(2017,5,12))
in
result
