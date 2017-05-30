section YoutubeAnalytics;

appKey="788332736108-vd8drvbcvvucv144mk3otrins2s95quc.apps.googleusercontent.com";
appSecret="9jc_XxF3E4XAHistah87vfpg";
redirectUrl = "http://127.0.0.1:81";
token_uri = "https://accounts.google.com/o/oauth2/token";
authorize_uri = "https://accounts.google.com/o/oauth2/auth";
logout_uri = "https://accounts.google.com/logout";
channel_id = "UCy_OwhQ_foCbaSKhMhuvgRw";
StartDate = "2012-01-01";
EndDate = Date.ToText(Date.From(DateTime.LocalNow()), "yyyy-MM-dd");

windowWidth = 720;
windowHeight = 1024;
// See https://developers.google.com/identity/protocols/googlescopes for scopes 
scope_prefix = "https://www.googleapis.com/auth/";
scopes = {
"yt-analytics-monetary.readonly", 
"yt-analytics.readonly", 
"youtubepartner", 
"youtube.readonly",
"youtube",
"youtubepartner"
};
Value.IfNull = (a, b) => if a <> null then a else b;

GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
    let
        prefix = Value.IfNull(scopePrefix, ""),
        addPrefix = List.Transform(scopes, each prefix & _),
        asText = Text.Combine(addPrefix, " ")
    in
        asText;


       
[DataSource.Kind="YoutubeAnalytics", Publish="YoutubeAnalytics.Publish"]
shared YoutubeAnalytics.VideoStats = () =>
  let
    MainTable = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("LdRbcqMwEAXQveR7NmEECAwiiiXw2KnsfxuTmtNft8Dd9yXh7++P2/zx8+cX/oL9P4xvTw2M4BOs4Atk8AAFPMEJOsA54BwWgHoYwAtMIBbuAPWAbOBlYGK4AbLDBVhaY/IA7A5CD6IkCxtLiVDCubGULHR2k5YSzqS6lAC9LVjopdjbAGeJ+hJPykoypJBVwWhv1MSIeiQ0kZ0INVGyXibUkz4n1c3IZuszzpmX2UKWtkZokBWSqWecI8iqy1hysGgpy54rEDPzkrnOisyyZ9kXIwu9i/picpFhQba6UqvfVnprHL8mVj5XZCtnK4W7l3cG7ybvcYwOYPNyk28zuVHYuN5E2fncncPuXu8M7hZ2+XZkOxO7KIVska/gLBSKvYK6yFCsFwdQpC2ECs5XjLims7RFS8XtKaorYhZ2iyhFBcXe4eVB4dDEwcuB7LBwyHfgPEQ5WDpcqRLrQn9SqLJXoSsvlWzFUjVRUVfZqwyVlyp05fPL+sPCg96Dl0f8a9hryDZke9QT30NcRS+fnDUvG71GqFl/xIiFFgrxpTqOJm1TVnNfGoPv+OKCBUxxl2LPMTYxm4+5OYAmbZKo6axL2012k91IZ7Az2Cl0Xrp8XbBOr8ve5esu5mn9ZP4WfxCCncyf9k6WTiYux3FZuAhdyC71PJ3DxO7L5BvZW7D3L9nPPw==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [#"Country code" = _t]),
    Countries = Table.TransformColumns(MainTable,{},Text.Lower),
    Source = Web.Contents("https://www.googleapis.com/youtube/v3/search?channelId=UCy_OwhQ_foCbaSKhMhuvgRw&part=snippet,id&order=date&maxResults=50"),
    #"Imported JSON" = Json.Document(Source),
    items = #"Imported JSON"[items],
    #"Converted to Table" = Table.FromList(items, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"kind", "etag", "id", "snippet"}, {"kind", "etag", "id", "snippet"}),
    #"Expanded id" = Table.ExpandRecordColumn(#"Expanded Column1", "id", {"videoId"}, {"videoId"}),
    #"Expanded snippet" = Table.ExpandRecordColumn(#"Expanded id", "snippet", {"publishedAt", "title", "description", "thumbnails", "liveBroadcastContent"}, {"publishedAt", "title", "description", "thumbnails", "liveBroadcastContent"}),
    #"Se expandió thumbnails" = Table.ExpandRecordColumn(#"Expanded snippet", "thumbnails", {"default", "medium", "high"}, {"default", "medium", "high"}),
    #"Se expandió high" = Table.ExpandRecordColumn(#"Se expandió thumbnails", "high", {"url"}, {"url"}),
    #"Expanded default" = Table.ExpandRecordColumn(#"Se expandió high", "default", {"url"}, {"url.1"}),
    #"Expanded medium" = Table.ExpandRecordColumn(#"Expanded default", "medium", {"url"}, {"url.2"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded medium",{{"url.1", "Default Thumbnail"}, {"url.2", "Medium Thumbnail"}, {"url", "High Thumbnail"}}),
    #"Filtered Rows" = Table.SelectRows(#"Renamed Columns", each ([videoId] <> null)),
    #"Removed Columns" = Table.RemoveColumns(#"Filtered Rows",{"kind", "etag"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"videoId", type text}, {"title", type text}, {"description", type text}, {"Default Thumbnail", type text}, {"Medium Thumbnail", type text}, {"High Thumbnail", type text}, {"liveBroadcastContent", type text}, {"publishedAt", type datetimezone}}),
    videos = Text.Combine(List.Transform(#"Changed Type"[videoId], Text.From), "%2C"),
    #"Added Custom" =  Table.AddColumn(Countries, "Response", 
             each Json.Document(
                     Web.Contents("https://www.googleapis.com/youtube/analytics/v1/reports?ids=channel%3D%3D"&channel_id&"&start-date="&StartDate&"&end-date="& EndDate &"&metrics=views%2Clikes%2Cdislikes%2Cshares%2CestimatedRevenue%2Ccomments%2CsubscribersGained%2CsubscribersLost&dimensions=day%2Cvideo&filters=video%3D%3D"&videos&"%3Bcountry%3D%3D"&[Country code]))),
#"Expanded Custom.1" = Table.ExpandRecordColumn(#"Added Custom", "Response", {"rows"}, {"rows"}),
    #"Filtered Rows1" = Table.SelectRows(#"Expanded Custom.1", each [rows] <> null),
    #"Expanded rows" = Table.ExpandListColumn(#"Filtered Rows1", "rows"),
    #"Added Custom2" = Table.AddColumn(#"Expanded rows", "Custom", each Table.Transpose(Table.FromList([rows], Splitter.SplitByNothing()))),
    #"Removed Columns2" = Table.RemoveColumns(#"Added Custom2",{"rows"}),
    #"Expanded Custom" = Table.ExpandTableColumn(#"Removed Columns2", "Custom", {"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8"}, {"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Expanded Custom",{{"Column1", "Date"}, {"Column2", "VideoID"}, {"Column3", "Views"}, {"Column4", "Likes"}, {"Column5", "Dislikes"}, {"Column6", "Shares"}, {"Column7", "estimatedRevenue"}, {"Column8", "comments"}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Renamed Columns1",{{"comments", Int64.Type}, {"Shares", Int64.Type}, {"Dislikes", Int64.Type}, {"Likes", Int64.Type}, {"Views", Int64.Type}, {"estimatedRevenue", type number}, {"VideoID", type text}, {"Date", type date}})
in
    #"Changed Type1";
       
    
// Data Source Kind description
YoutubeAnalytics = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
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

YoutubeAnalytics.Icons = [
    Icon16 = { Extension.Contents("PQExtension116.png"), Extension.Contents("PQExtension120.png"), Extension.Contents("PQExtension124.png"), Extension.Contents("PQExtension132.png") },
    Icon32 = { Extension.Contents("PQExtension132.png"), Extension.Contents("PQExtension140.png"), Extension.Contents("PQExtension148.png"), Extension.Contents("PQExtension164.png") }
];

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
        client_id = appKey,  
        redirect_uri = redirectUrl,   
        state="security_token",
        scope = GetScopeString(scopes, scope_prefix),
        response_type = "code",
        response_mode = "query",
        access_type="offline",
        login = "login"    
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
                   TokenMethod(parts[code])
    in
        result;

TokenMethod = (code) =>
    let
        response = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString([
                grant_type = "authorization_code",
                client_id = appKey,
                client_secret = appSecret,
                code = code,
                redirect_uri = redirectUrl])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),
        body = Json.Document(response),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;