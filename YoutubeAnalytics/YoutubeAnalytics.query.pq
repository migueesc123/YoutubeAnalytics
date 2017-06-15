// Use this file to write queries to test your data connector
let
    result = YoutubeAnalytics.GETReports (
             #date(2017,6,1), 
             #date(2017,6,3), 
             "views,estimatedRevenue", 
             "USD", 
             "day", 
             null, 
             null, 
             null, 
             null)
in
result
