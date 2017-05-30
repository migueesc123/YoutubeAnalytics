// Use this file to write queries to test your data connector
let
    result = YoutubeAnalytics.DailySubscribers( #date(2012,1,1), #date(2017,6,1))
in
    result