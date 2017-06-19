// Use this file to write queries to test your data connector
let
    result = Table.RowCount ( YoutubeAnalytics.Videos ())
in
result
