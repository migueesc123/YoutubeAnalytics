///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
/////////////                                                                 /////////////
/////////////    Title: Youtube Analytics Connector for Power BI              ///////////// 
/////////////    Created by: Miguel Escobar (@EscobarMiguel90)                ///////////// 
/////////////    Website: https://github.com/migueesc123/YoutubeAnalytics     ///////////// 
/////////////                                                                 ///////////// 
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

section YoutubeAnalytics;

appKey= Json.Document ( Extension.Contents( "WebApp.json") ) [web][client_id];
appSecret= Json.Document ( Extension.Contents( "WebApp.json") ) [web][client_secret];
redirectUrl = Json.Document ( Extension.Contents( "WebApp.json") )  [web][redirect_uris]{0};
token_uri = Json.Document ( Extension.Contents( "WebApp.json") )  [web][token_uri];
authorize_uri = Json.Document ( Extension.Contents( "WebApp.json") )  [web][auth_uri];
logout_uri = "https://accounts.google.com/logout";
                                                              
windowWidth = 720;
windowHeight = 1024;


//// We define the scopes which are simply the types of access the the OAuth will provide
//// See https://developers.google.com/identity/protocols/googlescopes for scopes 
scope_prefix = "https://www.googleapis.com/auth/";
scopes = {
"yt-analytics-monetary.readonly", 
"yt-analytics.readonly",  
"youtube.readonly"
};


[DataSource.Kind="YoutubeAnalytics", Publish="YoutubeAnalytics.Publish"]
shared YoutubeAnalytics.Navigation = Value.ReplaceType(Navigation, NavigationType);


NavigationType = type function () as table meta [                  
        Documentation.Name = "Youtube Analytics",
        Documentation.LongDescription = "Returns a table with key Youtube Data API and Youtube Analytics API data",
        Documentation.Examples = {[
            Description = "Returns a table with key Youtube Data API and Youtube Analytics API data",
            Code = "YoutubeAnalytics.Navigation () ",
            Result = "A table with key Youtube Data API and Youtube Analytics API data"
        ]}
    ];


 Navigation = () =>
    let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Channel",      "YoutubeAnalytics.ChannelInfo",      YoutubeAnalytics.ChannelInfo(), "Table",    "Table",    true},
            {"Videos",      "YoutubeAnalytics.Videos",      YoutubeAnalytics.Videos(), "Table",    "Table",    true},
            {"Countries",      "YoutubeAnalytics.Countries",      YoutubeAnalytics.Countries(), "Table",    "Table",    true}, 
            {"Video Stats", "YoutubeAnalytics.VideoStats", YoutubeAnalytics.VideoStats,       "Function", "Function", true},
            {"Daily Subscribers", "YoutubeAnalytics.DailySubscribers", YoutubeAnalytics.DailySubscribers,       "Function", "Function", true},
            {"GET Reports", "YoutubeAnalytics.GETReports", YoutubeAnalytics.GETReports,       "Function", "Function", true},
            {"GET Public Data", "YoutubeAnalytics.GETPublicData", YoutubeAnalytics.GETPublicData,       "Function", "Function", true}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

 [DataSource.Kind="YoutubeAnalytics"]
 shared YoutubeAnalytics.GETReports =   Value.ReplaceType(GetReports,GetReportsType);
 

GetReportsType = type function (
    optional PStartDate as (type date meta [ 
        Documentation.FieldCaption = "Start Date"
    ]),
     optional PEndDate as (type date meta [ 
        Documentation.FieldCaption = "End Date"
    ]),
     optional Pmetrics as (type text meta [
        Documentation.FieldCaption = "Metrics",
        Documentation.SampleValues = {"views,likes,shares"}
    ]),
       optional Pcurrency as (type text meta [
        Documentation.FieldCaption = "Currency",
        Documentation.FieldDescription = "Three-letter, ISO 4217 currency code",
        Documentation.SampleValues = {"EUR", "USD"}
    ]),
        optional Pdimensions as (type text meta [
        Documentation.FieldCaption = "Dimensions",
        Documentation.SampleValues = {"day,deviceType"}
    ]),
      optional Pfilters as (type text meta [
        Documentation.FieldCaption = "Filters",
        Documentation.SampleValues = {"country==US;deviceType==MOBILE"}
    ]),
      optional Pmax_results as (type number meta [
        Documentation.FieldCaption = "Max Results"
    ]),
         optional Psort as (type text meta [
        Documentation.FieldCaption = "Sort",
        Documentation.SampleValues = {"day", "-day"}
    ]),
      optional Pstart_index as (type number meta [
        Documentation.FieldCaption = "Max Results"
    ]))
    as table meta [
        Documentation.Name = "Youtube Analytics API v1 GET data",
        Documentation.LongDescription = "Read the full Youtube Analytics API documentation from Google and find how to construct your query at: https://developers.google.com/youtube/analytics/v1/data_model",
        Documentation.Examples = {[
            Description = "Quick query to get the views and estimatedRevenue in USD by day from June 1st, 2017 until June 3rd, 2017",
            Code = "Check the Documentation at: https://developers.google.com/youtube/analytics/v1/data_model
            
            Example: 
            YoutubeAnalytics.GETReports (
             #date(2017,6,1), 
             #date(2017,6,3), 
             ""views,estimatedRevenue"", 
             ""USD"", 
             ""day"", 
             null, 
             null, 
             null, 
             null)",
                        Result = "#table({""day"",""views"",""estimatedRevenue""},{
                        {""2017-06-01"",""230"",""0.4""},
                        {""2017-06-02"",""255"",""0.403""},
                        {""2017-06-03"",""386"",""0.772""}}))"
        ]}
    ];

  
    GetReports =  (
 optional PStartDate as date, 
 optional PEndDate as date, 
 optional Pmetrics as text, 
 optional Pcurrency as text, 
 optional Pdimensions as text, 
 optional Pfilters as text, 
 optional Pmax_results as number , 
 optional Psort as text, 
 optional Pstart_index as number) as table =>
     let
       Start = Date.ToText ( PStartDate, "yyyy-MM-dd"),
      End =  Date.ToText ( PEndDate, "yyyy-MM-dd"),
     channel_id = Json.Document( Web.Contents( "https://www.googleapis.com/youtube/v3/channels?mine=true&part=id" ) ) [items] {0} [id],
    requesturl = "https://www.googleapis.com/youtube/analytics/v1/reports",
    GETInfo= [ 
        ids = "channel==" & channel_id,
        #"start-date" = Start,
       #"end-date" = End,
        metrics = Pmetrics,
        currency = Pcurrency,
        dimensions=Pdimensions,
        filters= Pfilters,
        #"max-results"= Number.ToText( Pmax_results ),
        sort = Psort,
        #"start-index"= Number.ToText( Pstart_index )],
    CleanedRecord = Record.RemoveFields( GETInfo,  Table.SelectRows( Record.ToTable ( GETInfo), each ([Value] = null))[Name]),
    Request= 
        Json.Document(
                     Web.Contents( requesturl, [RelativePath = "?" & Uri.BuildQueryString(CleanedRecord)] ) ),
    ColumnHeaders = Table.FromRecords( Request[columnHeaders] )[name],
    DataValues =  List.Transform( Request[rows], each Record.FromList( _, ColumnHeaders)),
    OutputTable = Table.FromRecords ( DataValues)
        in 
            OutputTable;

[DataSource.Kind="YoutubeAnalytics"]
 shared YoutubeAnalytics.GETPublicData =  Value.ReplaceType(GETPublicData, GETPublicDataType) ;
 
 GETPublicDataType = type function (
        optional path as ( type text meta[
        Documentation.FieldCaption = "url Path",
        Documentation.FieldDescription = "Text string to be added to the https://www.googleapis.com/youtube/v3/"]
        )) as table meta [                  
        Documentation.Name = "YoutubeAnalytics.GETPublicData",
        Documentation.LongDescription = "Makes a call to the Youtube Data API and returns the raw response",
        Documentation.Examples = {[
            Description = "Returns raw data from any of the https://www.googleapis.com/youtube/v3/ endpoints. ",
            Code = "YoutubeAnalytics.GETPublicData(""search?part=snippet&maxResults=50&q=Power+BI"")
            Get the full documentation at  https://developers.google.com/youtube/v3/docs/ ",
            Result = "Raw search in Record format for the word Power BI with 50 as maximum result records."
        ]}
    ]; 

GETPublicData = (optional path as text) =>
 let
     requesturl = "https://www.googleapis.com/youtube/v3/",
     response = Json.Document( Web.Contents ( requesturl, [RelativePath = path]) )
     in
         response;

 [DataSource.Kind="YoutubeAnalytics"]
YoutubeAnalytics.ChannelInfo = () as table =>
let
    Source = Web.Contents("https://www.googleapis.com/youtube/v3/channels?mine=true&part=snippet,statistics"),
    #"Imported JSON" = Json.Document(Source),
    items = #"Imported JSON"[items],
    #"Converted to Table" = Table.FromList(items, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"kind", "etag", "id", "snippet", "statistics"}, {"kind", "etag", "id", "snippet", "statistics"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded Column1",{"kind", "etag", "id"}),
    #"Expanded snippet" = Table.ExpandRecordColumn(#"Removed Columns", "snippet", {"title", "description", "customUrl", "publishedAt", "thumbnails", "localized", "country"}, {"title", "description", "customUrl", "publishedAt", "thumbnails", "localized", "country"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded snippet",{{"title", "Channel Name"}, {"description", "Channel Description"}}),
    #"Expanded thumbnails" = Table.ExpandRecordColumn(#"Renamed Columns", "thumbnails", {"default", "medium", "high"}, {"default", "medium", "high"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded thumbnails",{"localized"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Removed Columns1",{{"country", "Country"}}),
    #"Expanded default" = Table.ExpandRecordColumn(#"Renamed Columns1", "default", {"url"}, {"url"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Expanded default",{{"url", "Default Channel Avatar"}}),
    #"Expanded medium" = Table.ExpandRecordColumn(#"Renamed Columns2", "medium", {"url"}, {"url"}),
    #"Renamed Columns3" = Table.RenameColumns(#"Expanded medium",{{"url", "Medium Channel Avatar"}}),
    #"Expanded high" = Table.ExpandRecordColumn(#"Renamed Columns3", "high", {"url"}, {"url"}),
    #"Renamed Columns4" = Table.RenameColumns(#"Expanded high",{{"url", "HighChannel Avatar"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns4",{{"HighChannel Avatar", type text}, {"Medium Channel Avatar", type text}, {"Default Channel Avatar", type text}, {"customUrl", type text}, {"Channel Description", type text}, {"Channel Name", type text}, {"publishedAt", type datetimezone}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "Custom Channel url", each "https://www.youtube.com/"&[customUrl]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom",{{"Custom Channel url", type text}}),
    #"Removed Columns2" = Table.RemoveColumns(#"Changed Type1",{"customUrl"}),
    #"Expanded statistics" = Table.ExpandRecordColumn(#"Removed Columns2", "statistics", {"viewCount", "subscriberCount", "videoCount"}, {"viewCount", "subscriberCount", "videoCount"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Expanded statistics",{{"viewCount", Int64.Type}, {"subscriberCount", Int64.Type}, {"videoCount", Int64.Type}})
in
    #"Changed Type2";
     
[DataSource.Kind="YoutubeAnalytics"]
shared YoutubeAnalytics.VideoStats   = Value.ReplaceType(VideoStats, VideoStatsType);

VideoStatsType = type function (
        optional StartDate as ( type date meta[
        Documentation.FieldCaption = "Start Date",
        Documentation.FieldDescription = "The Start Date of the report"]),
        optional EndDate as( type date meta[
        Documentation.FieldCaption = "End Date",
        Documentation.FieldDescription = "The End Date of the report"]),
        optional Partnership as( type logical meta [
        Documentation.FieldCaption = "Are you a Partner?",
        Documentation.FieldDescription = "If you are a Partner then choose true",
        Documentation.AllowedValues = { true, false }])) 
        as table meta [                  
        Documentation.Name = "Youtube Analytics Daily Video Activity by Country",
        Documentation.LongDescription = "Returns a table with daily information by country and video for views,likes,dislikes,shares,estimatedRevenue,comments,
         averageViewDuration,estimatedMinutesWatched,adImpressions,cpm,averageViewPercentage,subscribersGained, and subscribersLost",
        Documentation.Examples = {[
            Description = "Returns a table with daily information by country and video for views,likes,dislikes,shares,estimatedRevenue,comments,
         averageViewDuration,estimatedMinutesWatched,adImpressions,cpm,averageViewPercentage,subscribersGained, and subscribersLost",
            Code = "YoutubeAnalytics.Subscribers (#date(2013,1,1), #date(2017,6,3))",
            Result = "#table({""Country code"",""day"",""video"",""views"",""likes"",""dislikes"",""shares"",""estimatedRevenue"",""comments"",""averageViewDuration"",""estimatedMinutesWatched"",""adImpressions"",""cpm"",""averageViewPercentage"",""subscribersGained"",""subscribersLost""},{
            {""af"",""4/9/2013"",""3Qn0RA5zwxg"",""1"",""0"",""0"",""0"",""0"",""0"",""214"",""3"",""0"",""0"",""88.91244813278009"",""0"",""0""},
            {""af"",""5/19/2013"",""pjNkqvuisbo"",""2"",""0"",""0"",""0"",""0"",""0"",""2"",""0"",""0"",""0"",""0.6909214092140921"",""0"",""0""},
            {""af"",""11/26/2013"",""QZXB9dB8SlA"",""1"",""0"",""0"",""0"",""0"",""0"",""29"",""0"",""0"",""0"",""6.5988687782805435"",""0"",""0""},
            {""af"",""2/9/2014"",""HMg0sWFZym4"",""1"",""0"",""0"",""0"",""0"",""0"",""14"",""0"",""0"",""0"",""4.46969696969697"",""0"",""0""}})"
        ]}
    ]
;

VideoStats = ( optional StartDate as date, optional EndDate as date, optional Partnership as logical)  =>
  let
      channel_id = Json.Document(Web.Contents("https://www.googleapis.com/youtube/v3/channels?mine=true&part=id"))[items]{0}[id],
   VidsBaseurl = "https://www.googleapis.com/youtube/v3/search?part=id&order=date&maxResults=50&forMine=true&type=video&pageToken=",
    requesturl = "https://www.googleapis.com/youtube/analytics/v1/reports",
    monetaryMetrics = {"estimatedRevenue","adImpressions","cpm"},
    regularMetrics = {"views","likes","dislikes","shares","comments","averageViewDuration","estimatedMinutesWatched",
                    "averageViewPercentage","subscribersGained","subscribersLost"},
    metricsToGET = if Partnership = true or Partnership = null  then List.Combine( {monetaryMetrics, regularMetrics}) else regularMetrics,
    Source = List.Generate( ()=> 
     [Result = null , nextPageToken =null, prevPageToken= null, Counter = 0], 
each [nextPageToken] <> null or [prevPageToken] <> null  or [Counter] <= 1 , 
 each  [Result =  if [nextPageToken] = null and [prevPageToken] = null then 
       Json.Document(
            Web.Contents(
             VidsBaseurl)) 
    else Json.Document(
             Web.Contents(
            VidsBaseurl,  [ Query  = [pageToken=Text.From( [nextPageToken]) ]])), 
  nextPageToken = try Result[nextPageToken] otherwise null, 
 prevPageToken = try Result[prevPageToken] otherwise null,
    Counter = [Counter] + 1 ], each [Result]),
    #"Removed Top Items" = List.Skip(Source,1) ,
        ///End of Imke's code. Please visit her page! http://www.thebiccountant.com/
    #"Converted to Table" = Table.FromList(#"Removed Top Items", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"items"}, {"items"}),
    #"Expanded items" = Table.ExpandListColumn(#"Expanded Column1", "items"),
    #"Expanded items1" = Table.ExpandRecordColumn(#"Expanded items", "items", {"id"}, {"id"}),
    #"Expanded id" = Table.ExpandRecordColumn(#"Expanded items1", "id", {"videoId"}, {"videoId"}),
    VidNoNulls = Table.SelectRows(#"Expanded id", each [videoId] <> null and [videoId] <> ""),
       VideoList = List.Buffer(VidNoNulls[videoId]),
       maxIterations = Number.RoundUp( List.Count( VideoList) /200),
       setofVideos= List.Generate( () =>
              [Result = Text.Combine(List.Transform(List.Range(VideoList,0,200), Text.From), ","), Offset = 0, Counter = 0],
                    each [Counter] < maxIterations,
                    each [Result = Text.Combine( List.Transform(List.Range(VideoList,[Offset]+200,200), Text.From), ","),
                Counter = [Counter] +1,
                Offset = [Offset] + 200], each [Result]),
      Start = Date.ToText ( StartDate, "yyyy-MM-dd"),
      End =  Date.ToText ( EndDate, "yyyy-MM-dd"),
     videos = Text.Combine(List.Transform(VideoList, Text.From), ","),
     AddingCountriesColumn = Table.TransformColumns(Table.SelectColumns(YoutubeAnalytics.Countries(),{"Country code"}),{},Text.Lower),
     AddingSetofVideos = Table.AddColumn(AddingCountriesColumn, "VideoIDs", each setofVideos),
     BeforeMakingTheCall = Table.ExpandListColumn(AddingSetofVideos,  "VideoIDs"),
    #"Added Custom" =  Table.AddColumn( BeforeMakingTheCall , "Response", 
             each  try Json.Document(
                     Web.Contents( requesturl, 
                     [RelativePath = "?" & Uri.BuildQueryString([
       ids = "channel==" & channel_id,   
        #"start-date" = Start,
       #"end-date" = End,
        metrics = Text.Combine( List.Transform( metricsToGET, Text.From), ","),
        dimensions="day,video",
        filters = "video=="&[VideoIDs]&";country=="&[Country code]    
    ])])) otherwise null),
    removingHelperColumn = Table.RemoveColumns ( #"Added Custom", {"VideoIDs"}),  
    columnHeaders = List.Buffer( Table.FromRecords(removingHelperColumn{0}[Response][columnHeaders])[name]),
    DataInLists = Table.ExpandListColumn( Table.SelectRows(Table.ExpandRecordColumn(removingHelperColumn, "Response", {"rows"}, {"rows"}), each [rows] <> null),  "rows"), 
    DatainRecords = Table.AddColumn(DataInLists, "Custom", each Record.FromList( [rows], columnHeaders)),
    RemovingDataInList = Table.RemoveColumns(DatainRecords,{"rows"}),
    DataInTable = Table.ExpandRecordColumn(RemovingDataInList, "Custom", columnHeaders),
    OutputTable =  Table.TransformColumnTypes(DataInTable,  if Partnership = true or Partnership = null then
      {{"comments", Int64.Type}, 
       {"shares", Int64.Type}, 
       {"dislikes", Int64.Type}, 
       {"likes", Int64.Type}, 
       {"views", Int64.Type}, 
       {"estimatedRevenue", type number}, 
       {"video", type text}, 
       {"day", type date},
       {"averageViewDuration", type number},
       {"estimatedMinutesWatched", type number},
       {"adImpressions", type number},
       {"cpm", type number},
       {"averageViewPercentage", type number},
       {"subscribersGained", type number},
       {"subscribersLost", type number}} 
       else
       {{"comments", Int64.Type}, 
       {"shares", Int64.Type}, 
       {"dislikes", Int64.Type}, 
       {"likes", Int64.Type}, 
       {"views", Int64.Type},  
       {"video", type text}, 
       {"day", type date},
       {"averageViewDuration", type number},
       {"estimatedMinutesWatched", type number},
       {"averageViewPercentage", type number},
       {"subscribersGained", type number},
       {"subscribersLost", type number}}),

///Information about the metrics that are used https://developers.google.com/youtube/analytics/v1/dimsmets/mets

    result = if StartDate = null  and EndDate =null then Error.Record("Parameters Issue", "StartDate and EndDate can not be null", "StartDate = null & EndDate = null") else 
           if StartDate = null then Error.Record("Parameters Issue", "StartDate can not be null", "StartDate = null") else 
           if EndDate = null then Error.Record("Parameters Issue", "EndDate can not be null", "EndDate = null") else
           if Number.From(StartDate) > Number.From(EndDate) then Error.Record("Parameters Issue","StartDate can't be after EndDate", "StartDate > EndDate") else OutputTable
in
    result;

[DataSource.Kind="YoutubeAnalytics"]
shared YoutubeAnalytics.DailySubscribers  = Value.ReplaceType(DailySubscribers, DailySubscribersType);

DailySubscribersType = type function (
        optional StartDate as ( type date meta[
        Documentation.FieldCaption = "Start Date",
        Documentation.FieldDescription = "The Start Date of the report"]),
        optional EndDate as( type date meta[
        Documentation.FieldCaption = "End Date",
        Documentation.FieldDescription = "The End Date of the report"]
        )) as table meta [                  
        Documentation.Name = "Youtube Analytics Daily Subscribers",
        Documentation.LongDescription = "Returns a table with daily information for subscribersGained and subscribersLost within the time period provided and by country code",
        Documentation.Examples = {[
            Description = "Returns a table with daily information by country for subscribersGained and subscribersLost within the time period provided",
            Code = "YoutubeAnalytics.Subscribers (#date(2017,6,1), #date(2017,6,3))",
            Result = "#table({""Country code"",""day"",""subscribersGained"",""subscribersLost""},{
            {""af"",""4/9/2013"",""0"",""0""},
            {""af"",""5/19/2013"",""0"",""0""},
            {""af"",""11/26/2013"",""0"",""0""},
            {""af"",""2/9/2014"",""0"",""0""}})"
        ]}
    ]
;

DailySubscribers = (optional StartDate as date, optional EndDate as date) =>
 ///*****Data for "Subscribers lost" and "Subscribers" is not correctly tracked between August 20, 2013 and August 23, 2013
 ////*****Data for "Subscribers gained", "Subscribers lost", and "Subscribers" is not correctly tracked between January 13, 2015 and January 15, 2015.
  let
      channel_id = Json.Document(Web.Contents("https://www.googleapis.com/youtube/v3/channels?mine=true&part=id"))[items]{0}[id],
          requesturl = "https://www.googleapis.com/youtube/analytics/v1/reports",
      Start = Date.ToText ( StartDate, "yyyy-MM-dd"),
      End =  Date.ToText ( EndDate, "yyyy-MM-dd"),
    #"Added Custom" =  Table.AddColumn(Table.TransformColumns(Table.SelectColumns(YoutubeAnalytics.Countries(),{"Country code"}),{},Text.Lower) , "Response", 
             each Json.Document(
                     Web.Contents( requesturl, [RelativePath = "?" & Uri.BuildQueryString([
       ids = "channel==" & channel_id,   
        #"start-date" = Start,
       #"end-date" = End,
        metrics = Text.Combine( List.Transform(
         {"subscribersGained","subscribersLost"}, Text.From), ","),
        dimensions="day",
        filters = "country=="&[Country code]    
    ])]))),
///Information about the metrics that are used https://developers.google.com/youtube/analytics/v1/dimsmets/mets
 responseColumnHeaders = Table.ExpandRecordColumn ( Table.FromList(#"Added Custom"[Response]{0}[columnHeaders],Splitter.SplitByNothing(), null, null, ExtraValues.Error),  "Column1", {"name", "columnType", "dataType"}),
 responseColumnNames = responseColumnHeaders[name],
#"Expanded Custom.1" = Table.ExpandRecordColumn(#"Added Custom", "Response", {"rows"}, {"rows"}),
    #"Filtered Rows1" = Table.SelectRows(#"Expanded Custom.1", each [rows] <> null),
    #"Expanded rows" = Table.ExpandListColumn(#"Filtered Rows1", "rows"),
    #"Added Custom2" = Table.AddColumn(#"Expanded rows", "Custom", each Table.Transpose(Table.FromList([rows], Splitter.SplitByNothing()))),
    #"Removed Columns2" = Table.RemoveColumns(#"Added Custom2",{"rows"}),
    ColumnsToExpand = Table.ColumnNames(#"Removed Columns2"[Custom]{0}),
    #"Expanded Custom" = Table.ExpandTableColumn(#"Removed Columns2", "Custom", 
    ColumnsToExpand, 
    responseColumnNames),
      #"Changed Type1" = Table.TransformColumnTypes(#"Expanded Custom",
      {{"day", type date},
       {"subscribersGained", type number},
       {"subscribersLost", type number}}),
    result = if StartDate = null  and EndDate =null then Error.Record("Parameters Issue", "StartDate and EndDate can not be null", "StartDate = null & EndDate = null") else 
           if StartDate = null then Error.Record("Parameters Issue", "StartDate can not be null", "StartDate = null") else 
           if EndDate = null then Error.Record("Parameters Issue", "EndDate can not be null", "EndDate = null") else
           if Number.From(StartDate) > Number.From(EndDate) then Error.Record("Parameters Issue","StartDate can't be after EndDate", "StartDate > EndDate") else #"Changed Type1"
in
    result;
                  

[DataSource.Kind="YoutubeAnalytics"]
YoutubeAnalytics.Countries = () as table =>
 let
    Source= Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("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", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [Country = _t, #"Country code" = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Country", type text}, {"Country code", type text}})
in
    #"Changed Type";
    
[DataSource.Kind="YoutubeAnalytics"]
YoutubeAnalytics.Videos = () as table =>
let
    ///Code originally created by Imke http://www.thebiccountant.com/
    Baseurl = "https://www.googleapis.com/youtube/v3/search?part=snippet,id&order=date&maxResults=50&forMine=true&type=video",
    Source = List.Generate( ()=> 
     [Result = null , nextPageToken =null, prevPageToken= null, Counter = 0], 
each [nextPageToken] <> null or [prevPageToken] <> null  or [Counter] <= 1 , 
 each  [Result =  if [nextPageToken] = null and [prevPageToken] = null then 
       Json.Document(
            Web.Contents(
             Baseurl)) 
    else Json.Document(
             Web.Contents(
            Baseurl, [ Query  = [pageToken=Text.From( [nextPageToken]) ]])), 
  nextPageToken = try Result[nextPageToken] otherwise null, 
 prevPageToken = try Result[prevPageToken] otherwise null,
    Counter = [Counter] + 1 ], each [Result]),
    #"Removed Top Items" = List.Skip(Source,1),
    ///End of Imke's code. Please visit her page! http://www.thebiccountant.com/
    #"Converted to Table" = Table.FromList(#"Removed Top Items", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"items"}, {"items"}),
    #"Expanded items" = Table.ExpandListColumn(#"Expanded Column1", "items"),
    #"Expanded items1" = Table.ExpandRecordColumn(#"Expanded items", "items", {"id", "snippet"}, {"id", "snippet"}),
    #"Expanded id" = Table.ExpandRecordColumn(#"Expanded items1", "id", {"videoId"}, {"videoId"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded id", each [videoId] <> null and [videoId] <> ""),
    #"Expanded snippet" = Table.ExpandRecordColumn(#"Filtered Rows", "snippet", {"publishedAt", "title", "description", "thumbnails", "liveBroadcastContent"}, {"publishedAt", "title", "description", "thumbnails", "liveBroadcastContent"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded snippet",{{"publishedAt", type datetimezone}, {"title", type text}, {"description", type text}, {"liveBroadcastContent", type text}, {"videoId", type text}}),
    #"Expanded thumbnails" = Table.ExpandRecordColumn(#"Changed Type", "thumbnails", {"default", "medium", "high"}, {"default", "medium", "high"}),
    default = Table.ExpandRecordColumn(#"Expanded thumbnails", "default", {"url"}, {"url"}),
    medium = Table.ExpandRecordColumn(default, "medium", {"url"}, {"url.1"}),
    high = Table.ExpandRecordColumn(medium, "high", {"url"}, {"url.2"}),
    #"Changed Type1" = Table.TransformColumnTypes(high,{{"url", type text}, {"url.1", type text}, {"url.2", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type1",{{"url", "Default Thumbnail"}, {"url.1", "Medium Thumbnail"}, {"url.2", "High Thumbnail"}}),
    AddColumn = Table.AddColumn( #"Renamed Columns", "MyRequest", each 
           Json.Document( Web.Contents("https://www.googleapis.com/youtube/v3/videos", [RelativePath = "?id=" & [videoId] &"&part=contentDetails"]))),
               #"Expanded MyRequest" = Table.ExpandRecordColumn(AddColumn, "MyRequest", {"items"}, {"items"}),
    #"Expanded items2" = Table.ExpandListColumn(#"Expanded MyRequest", "items"),
    #"Expanded items12" = Table.ExpandRecordColumn(#"Expanded items2", "items", {"contentDetails"}, {"contentDetails"}),
    #"Expanded contentDetails" = Table.ExpandRecordColumn(#"Expanded items12", "contentDetails", {"duration", "dimension", "definition", "caption", "licensedContent", "projection", "hasCustomThumbnail"}, {"duration", "dimension", "definition", "caption", "licensedContent", "projection", "hasCustomThumbnail"}),
    #"Changed Type12" = Table.TransformColumnTypes(#"Expanded contentDetails",{{"licensedContent", type logical}, {"hasCustomThumbnail", type logical}, {"caption", type logical}, {"projection", type text}, {"definition", type text}, {"dimension", type text}, {"duration", type duration}})
in
    #"Changed Type12";
 
// Data Source Kind description
YoutubeAnalytics = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Logout = Logout
        ]
    ],
    Label =  Extension.LoadString ("DataSourceLabel")
];

// Data Source UI publishing description
YoutubeAnalytics.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = YoutubeAnalytics.Icons,
    SourceTypeImage = YoutubeAnalytics.Icons
];

///// Youtube Official Branding https://www.youtube.com/yt/brand/downloads.html all rights reserved 

YoutubeAnalytics.Icons = [
    Icon16 = { Extension.Contents("YoutubeAnalytics16.png"), Extension.Contents("YoutubeAnalytics20.png"), Extension.Contents("YoutubeAnalytics24.png"), Extension.Contents("YoutubeAnalytics32.png") },
    Icon32 = { Extension.Contents("YoutubeAnalytics32.png"), Extension.Contents("YoutubeAnalytics40.png"), Extension.Contents("YoutubeAnalytics48.png"), Extension.Contents("YoutubeAnalytics64.png") }
];


///// The OAuth Workflow coded in M has the critical components of:
/////       StartLogin
/////       TokenMethod, and,
/////       FinishLogin 
/////       that are defined below

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
        client_id = appKey,  
        redirect_uri = redirectUrl,   
        state= state,
        scope = GetScopeString(scopes, scope_prefix),
        response_type = "code",
        access_type = "offline",
        prompt = "consent"
    ])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirectUrl,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        parts = Uri.Parts(callbackUri)[Query],
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                   TokenMethod("authorization_code", parts[code])
    in
        result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", refresh_token);

Logout = (token) => logout_uri;

TokenMethod = (grantType, code) =>
    let
        query = [
            grant_type = grantType,
            client_id = appKey,
            client_secret = appSecret,
            redirect_uri = redirectUrl
        ],

        // {CODE From Matt} added for Google API - field is "code" on initial auth, and "refresh_token" for refresh
        queryWithCode = if (grantType = "refresh_token") then [ refresh_token = code ] else [code = code],

        response = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString(query & queryWithCode)),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),
        body = Json.Document(response),
        result = if  (Record.HasFields(body, {"error", "error_description"})) then  
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;



////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                                                            ////////////
////////////The following functions are a set of helper functions provided by Microsoft ////////////
////////////                                                                           ////////////
///////////////////////////////////////////////////////////////////////////////////////////////////


//// Table Navigation function provided by Microsoft. 
//// Get the full example on how to create a Navigation Table from Microsoft here > https://github.com/Microsoft/DataConnectors/tree/master/samples/NavigationTable

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

//// Function to check if the text string exists or if it should grab the next string
//// Get the full example on why this function was created from Microsoft here > https://github.com/Microsoft/DataConnectors/blob/fe8cb91f694e476bd70c10b9295a815d7bfc42d7/samples/MyGraph/README.md

Value.IfNull = (a, b) => if a <> null then a else b;

//// Function to concatenate all the scopes and create a string for them
//// Get the full example on why this function was created from Microsoft here > https://github.com/Microsoft/DataConnectors/blob/fe8cb91f694e476bd70c10b9295a815d7bfc42d7/samples/MyGraph/README.md
GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
    let
        prefix = Value.IfNull(scopePrefix, ""),
        addPrefix = List.Transform(scopes, each prefix & _),
        asText = Text.Combine(addPrefix, " ")
    in
        asText;

//// Helper function to create sample tables
SampleTable = ( OutputTable as table) as text =>

let
    TableToTransform = Table.FirstN(OutputTable,2),        
    Headers = Text.Combine(List.Transform(Table.ColumnNames(TableToTransform), each """"""&Text.From(_)&""""""), ","),
    Data = Text.Combine(List.Transform(List.Transform(Table.ToRows(TableToTransform), each Text.Combine(List.Transform(_, (_)=> """"""&Text.From(_)&""""""), ",")), each "{"&_&"}"), ","),
    TableFormat = "#table({"&Headers&"},{"&Data&"})"
in
    TableFormat;