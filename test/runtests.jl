using SQLite, DataFrames, Dates, Test, CSV
using WRDSMerger

##


db = SQLite.DB(joinpath("data", "sql_data.sqlite"))

##
WRDSMerger.default_tables["comp_funda"] = "compa_funda"
WRDSMerger.default_tables["comp_fundq"] = "compa_fundq"
WRDSMerger.default_tables["crsp_stocknames"] = "crsp_stocknames"
WRDSMerger.default_tables["crsp_index"] = "crsp_dsi"
WRDSMerger.default_tables["crsp_stock_data"] = "crsp_dsf"
WRDSMerger.default_tables["crsp_delist"] = "crsp_dsedelist"
WRDSMerger.default_tables["crsp_a_ccm_ccmxpf_lnkhist"] = "crsp_a_ccm_ccmxpf_lnkhist"
WRDSMerger.default_tables["wrdsapps_ibcrsphist"] = "wrdsapps_ibcrsphist"
WRDSMerger.default_tables["comp_company"] = "comp_company"
WRDSMerger.default_tables["ff_factors"] = "ff_factors_daily"

##

df = comp_data(db) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, 2020, 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, Date(2020, 6, 30), 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, Date(2020, 6, 30), Date(2021)) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db; filters=Dict{String, String}()) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, annual=false, cols=["gvkey", "fyearq", "datadate", "fqtr", "saleq"]) |> dropmissing
println(size(df))
@test nrow(df) > 0

##

df = comp_data(db, ["001380", "002269"]) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"], 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"], 2020, 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"], Date(2020, 6, 30), 2020) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"], Date(2020, 6, 30), Date(2021)) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"]; filters=Dict{String, String}()) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = comp_data(db, ["001380", "002269"], annual=false, cols=["gvkey", "fyearq", "datadate", "fqtr", "saleq"]) |> dropmissing
println(size(df))
@test nrow(df) > 0


##

df = crsp_stocknames(db) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db; cols=["permno", "cusip", "ticker"]) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db, ["68389X10", "G2918310"]) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db, ["68389X10", "27828110"], cusip_col="ncusip") |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db, ["68389X10", "27828110"], cols=["permno", "cusip", "ticker"], cusip_col="ncusip") |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db, [10104, 11762]) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_stocknames(db, [10104, 11762], cols=["permno", "cusip", "ticker"]) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_market(db) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_market(db, Date(2020)) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_market(db, Date(2018), Date(2020)) |> dropmissing
println(size(df))
@test nrow(df) > 0

df = crsp_market(db; cols="ewretd") |> dropmissing
println(size(df))
@test nrow(df) > 0

x = WRDSMerger.merge_date_ranges(
    [
        Date(2019):Day(1):Date(2020),
        Date(2020):Day(1):Date(2021),
        Date(2018):Day(1):Date(2018, 6),
        Date(2018, 5):Day(1):Date(2018, 6),
        ]
    )
@test x == [Date(2018):Day(1):Date(2018, 6), Date(2019):Day(1):Date(2021)]

df_pull = DataFrame(
    permno=[10104, 11762, 10104],
    dateStart=[Date(2019, 1, 7), Date(2020, 1, 6), Date(2020, 12, 1)],
    dateEnd=[Date(2021), Date(2021), Date(2021, 2, 3)]
)
df = crsp_data(
    db,
    df_pull.permno;
    cols=["ret", "askhi", "prc"]
) |> dropmissing
println(size(df))
@test nrow(df) > 100

df = crsp_data(
    db,
    df_pull.permno,
    df_pull.dateStart;
    cols=["ret", "askhi", "prc"]
) |> dropmissing
println(size(df))
@test nrow(df) == 3


df = crsp_data(
    db,
    df_pull.permno,
    df_pull.dateStart,
    df_pull.dateEnd;
    cols=["ret", "askhi", "prc"]
) |> dropmissing
println(size(df))
@test nrow(df) > 100

df = crsp_data(
    db,
    Date(2015),
    Date(2021);
    cols=["ret", "askhi", "prc"]
)
println(size(df))
@test nrow(df) > 100

##

df = link_identifiers(db, [Permno(10104)], [Date(2020)], Cusip, NCusip, GVKey, Ticker, IbesTicker, show_tree=true, colnames=["Cusip" => "cusip", "CIK" => "cik"])
println(size(df))
println(df)
@test nrow(df) > 0

df = link_identifiers(db,  [GVKey(12142), GVKey("012142")], [Date(2020), Date(2020)], Permno, Cusip, NCusip, GVKey, Ticker, IbesTicker)
println(size(df))
println(df)
@test nrow(df) > 0


df = link_identifiers(db,  [CIK(1341439), CIK("0001341439")], [Date(2020), Date(2020)], IbesTicker)
println(size(df))
println(df)
@test nrow(df) > 0

df = link_identifiers(db,  [Ticker("ORCL")], [Date(2020)], Permno, Cusip, NCusip, GVKey, Ticker, IbesTicker)
println(size(df))
println(df)
@test nrow(df) > 0

df = link_identifiers(db,  [IbesTicker("ORCL")], [Date(2020)], Permno, Cusip, NCusip, GVKey, Ticker, IbesTicker)
println(size(df))
println(df)
@test nrow(df) > 0

df = link_identifiers(db, IbesTicker.(["ORCL", "ETN", "ETN"]), [Date(2020), Date(2020), Date(2010)], NCusip, Cusip)
println(size(df))
println(df)
@test nrow(df) == 3

##

df1 = DataFrame(
    id=[1, 1, 2, 2],
    date_start=[Date(2019), Date(2020), Date(2019), Date(2020)],
    date_end=[Date(2020), Date(2021), Date(2020, 6, 30), Date(2021)]
)
df2 = DataFrame(
    id=[1, 1, 1, 2, 2, 2],
    date=[Date(2018), Date(2019, 6, 30), Date(2020), Date(2020, 2), Date(2020, 7), Date(2019, 12, 31)]
)

temp = range_join(
    df1,
    df2,
    [:id],
    [
        WRDSMerger.Conditions("date_start", <=, "date"),
        WRDSMerger.Conditions("date_end", >, "date")
    ],
    jointype=:left
)

@test all(temp.date_start .<= temp.date .< temp.date_end)
@test nrow(temp) == 6

temp = range_join(
    df2,
    df1,
    [:id],
    [
        WRDSMerger.Conditions("date", >=, "date_start"),
        WRDSMerger.Conditions("date", <, "date_end")
    ],
    jointype=:right
)

@test all(temp.date_start .<= temp.date .< temp.date_end)
@test nrow(temp) == 6

temp = range_join(
    df1,
    df2,
    [:id],
    [
        WRDSMerger.Conditions("date_start", <=, "date"),
        WRDSMerger.Conditions("date_end", >, "date")
    ],
    jointype=:right
)

@test nrow(temp) == 7

temp = range_join(
    df1,
    df2,
    [:id],
    [
        WRDSMerger.Conditions("date_start", <=, "date"),
        WRDSMerger.Conditions("date_end", >, "date")
    ],
    minimize=[:date_end => :date],
    validate=(true, false)
)

@test nrow(temp) == 4

temp = range_join(
    df2,
    df1,
    [:id],
    [
        WRDSMerger.Conditions("date", >=, "date_start"),
        WRDSMerger.Conditions("date", <, "date_end")
    ],
    minimize=[:date => :date_end],
    validate=(true, false)
)

@test nrow(temp) == 5

temp = range_join(
    df1,
    df2,
    [:id],
    [
        WRDSMerger.Conditions("date_start", <=, "date"),
        WRDSMerger.Conditions("date_end", >, "date")
    ],
    jointype=:outer,
    join_conditions=[:and]
)

@test nrow(temp) == 7

temp = range_join(
    df1,
    df2,
    [:id],
    [
        WRDSMerger.Conditions("date_start", >, "date"),
        WRDSMerger.Conditions("date_end", <, "date")
    ],
    join_conditions=:or
)

@test all((|).(temp.date .< temp.date_start, temp.date .> temp.date_end))
@test nrow(temp) == 5