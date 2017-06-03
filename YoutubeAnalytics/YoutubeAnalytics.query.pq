// Use this file to write queries to test your data connector
let
    result = YoutubeAnalytics.VideoStats(#date(2017,5,31),#date(2017,6,2))
in
    result