
function calculate_car(
    data::Tuple{AbstractDataFrame, AbstractDataFrame},
    df::AbstractDataFrame;
    date_start::String="dateStart",
    date_end::String="dateEnd",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    df = copy(df)
    BusinessDays.initcache(:USNYSE)
    df[!, :businessDays] = bdayscount(:USNYSE, df[:, date_start], df[:, date_end]) .+ 1

    aggCols = names(df)

    crsp = data[1]
    crspM = data[2]

    crsp = leftjoin(crsp, crspM, on=:date)
    crsp[!, :car] = crsp[:, :ret] .- crsp[:, market_return]
    # crsp[!, :plus1] = crsp[:, :ret] .+ 1
    # crsp[!, :plus1m] = crsp[:, market_return] .+ 1
    rename!(crsp, :date => :retDate)
    rename!(crsp, market_return => "retm")

    df = range_join(
        df,
        crsp,
        [idcol],
        [
            Conditions(<=, date_start, :retDate),
            Conditions(>=, date_end, :retDate)
        ]
    )

    
    gd = groupby(df, aggCols)
    df = combine(gd, out_cols...)

    return df
end

function calculate_car(
    data::Tuple{AbstractDataFrame, AbstractDataFrame},
    df::AbstractDataFrame,
    ret_period::Tuple{<:DatePeriod, <:DatePeriod};
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    calculate_car(
        data,
        df,
        EventWindow(ret_period);
        date,
        idcol,
        out_cols,
        market_return
    )
end

function calculate_car(
    data::Tuple{AbstractDataFrame, AbstractDataFrame},
    df::AbstractDataFrame,
    ret_period::EventWindow;
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    df = copy(df)
    if date ∉ names(df)
        throw(ArgumentError("The $date column is not found in the dataframe"))
    end
    if idcol ∉ names(df)
        throw(ArgumentError("The $idcol column is not found in the dataframe"))
    end
    df[!, :dateStart] = df[:, date] .+ ret_period.s
    df[!, :dateEnd] = df[:, date] .+ ret_period.e

    return calculate_car(data, df; idcol, out_cols, market_return)
end

function calculate_car(
    conn::Union{LibPQ.Connection, DBInterface.Connection},
    df::AbstractDataFrame,
    ret_period::Tuple{<:DatePeriod, <:DatePeriod};
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    calculate_car(
        conn,
        df,
        EventWindow(ret_period);
        date,
        idcol,
        market_return,
        out_cols
    )
end

function calculate_car(
    conn::Union{LibPQ.Connection, DBInterface.Connection},
    df::AbstractDataFrame,
    ret_period::EventWindow;
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    df = copy(df)
    
    df[!, :dateStart] = df[:, date] .+ ret_period.s
    df[!, :dateEnd] = df[:, date] .+ ret_period.e

    return calculate_car(
        conn,
        df;
        date_start="dateStart",
        date_end="dateEnd",
        idcol,
        market_return,
        out_cols
    )
end

function calculate_car(
    conn::Union{LibPQ.Connection, DBInterface.Connection},
    df::AbstractDataFrame;
    date_start::String="dateStart",
    date_end::String="dateEnd",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    df = copy(df)


    crsp = crsp_data(conn, df; date_start, date_end)
    crspM = crsp_market(
        conn,
        dateStart = minimum(df[:, date_start]),
        dateEnd = maximum(df[:, date_end]),
        col = market_return
    )
    return calculate_car(
        (crsp, crspM),
        df;
        date_start,
        date_end,
        idcol,
        market_return,
        out_cols
    )
end



function calculate_car(
    data::Tuple{AbstractDataFrame, AbstractDataFrame},
    df::AbstractDataFrame,
    ret_periods::Vector{EventWindow};
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)


    df = copy(df)

    dfAll = DataFrame()

    for ret_period in ret_periods
        df[!, :name] .= repeat([ret_period], nrow(df))
        if size(dfAll, 1) == 0
            dfAll = calculate_car(data, df, ret_period; date, idcol, market_return, out_cols)
        else
            dfAll = vcat(dfAll, calculate_car(data, df, ret_period; date, idcol, market_return, out_cols))
        end
    end
    return dfAll
end

function calculate_car(
    conn::Union{LibPQ.Connection, DBInterface.Connection},
    df::AbstractDataFrame,
    ret_periods::Vector{EventWindow};
    date::String="date",
    idcol::String="permno",
    market_return::String="vwretd",
    out_cols=[
        ["ret", "vol", "shrout", "retm", "car"] .=> sum,
        ["car", "ret"] .=> std,
        ["ret", "retm"] => ((ret, retm) -> bhar=bhar_calc(ret, retm)) => "bhar",
        ["ret"] .=> buy_hold_return .=> ["bh_return"]
    ]
)
    
    df = copy(df)
    df_temp = DataFrame()

    for ret_period in ret_periods
        df[!, :dateStart] = df[:, date] .+ ret_period.s
        df[!, :dateEnd] = df[:, date] .+ ret_period.e
        if nrow(df_temp) == 0
            df_temp = df[:, [idcol, date, "dateStart", "dateEnd"]]
        else
            df_temp = vcat(df_temp, df[:, [idcol, date, "dateStart", "dateEnd"]])
        end
    end
    gdf = groupby(df_temp, [idcol, date])
    df_temp = combine(gdf, "dateStart" => minimum => "dateStart", "dateEnd" => maximum => "dateEnd")

    crsp = crsp_data(conn, df_temp)

    crspM = crsp_market(
        conn,
        dateStart = minimum(df_temp[:, :dateStart]),
        dateEnd = maximum(df_temp[:, :dateEnd]),
        col = market_return,
    )

    return calculate_car(
        (crsp, crspM),
        df,
        ret_periods;
        date,
        idcol,
        market_return,
        out_cols
    )

end

function calculate_car(
    data::Tuple{DataFrame, DataFrame},
    df::DataFrame,
    ff_est::FFEstMethod;
    date_start::String="dateStart",
    date_end::String="dateEnd",
    event_date::String="date",
    est_window_start::String="est_window_start",
    est_window_end::String="est_window_end",
    idcol::String="permno",
    suppress_warning::Bool=false
)
    crsp_raw = data[1]
    mkt_data = data[2]
    df = copy(df)
    make_ff_est_windows!(df,
        ff_est;
        date_start,
        date_end,
        est_window_start,
        est_window_end,
        suppress_warning,
        event_date
    )
    crsp_raw = leftjoin(
        crsp_raw,
        mkt_data,
        on=:date,
        validate=(false, true)
    )

    # My understanding is the original Fama French subtracted risk free
    # rate, but it does not appear WRDS does this, so I follow that
    # event_windows[!, :ret_rf] = event_windows.ret .- event_windows[:, :rf]
    # ff_est_windows[!, :ret_rf] = ff_est_windows.ret .- ff_est_windows[:, :rf]

    # I need to dropmissing here since not doing so creates huge problems
    # in the prediction component, where it thinks all of the data
    # is actually categorical in nature
    rename!(crsp_raw, "date" => "return_date")
    dropmissing!(crsp_raw, vcat([:ret], ff_est.ff_sym))
    gdf_crsp = groupby(crsp_raw, idcol)

    f = term(:ret) ~ sum(term.(ff_est.ff_sym))
    
    df[!, :car_ff] = Vector{Union{Missing, Float64}}(missing, nrow(df))
    df[!, :bhar_ff] = Vector{Union{Missing, Float64}}(missing, nrow(df))
    df[!, :std_ff] = Vector{Union{Missing, Float64}}(missing, nrow(df))
    df[!, :obs_event] = Vector{Union{Missing, Int}}(missing, nrow(df))
    df[!, :obs_ff] = Vector{Union{Missing, Int}}(missing, nrow(df))
    # for some reason, threading here drastically slows things down
    # on bigger datasets, for small sets it is sometimes faster
    # the difference primarily is in garbage collection, with large numbers
    # it alwasy ends up spending a ton of time garbage collecting
    for i in 1:nrow(df)
        temp = get(
            gdf_crsp,
            Tuple(df[i, idcol]),
            DataFrame()
        )
        nrow(temp) == 0 && continue
        fil_ff = filter_data(
            df[i, :],
            temp,
            [
                Conditions(<=, est_window_start, "return_date"),
                Conditions(>=, est_window_end, "return_date")
            ]
        )
        df[i, :obs_ff] = sum(fil_ff)
        sum(fil_ff) < ff_est.min_est && continue
        #temp_ff = temp[temp_ff, :]
        fil_event = filter_data(
            df[i, :],
            temp,
            [
                Conditions(<=, date_start, "return_date"),
                Conditions(>=, date_end, "return_date")
            ]
        )
        temp_event = temp[fil_event, :]
 
        nrow(temp_event) == 0 && continue

        rr = reg(temp[fil_ff, :], f)
        expected_ret = predict(rr, temp_event)
        df[i, :car_ff] = sum(temp_event.ret .- expected_ret)
        df[i, :std_ff] = sqrt(rr.rss / rr.dof_residual) # similar to std(rr.residuals), corrects for the number of parameters
        df[i, :bhar_ff] = bhar_calc(temp_event.ret, expected_ret)
        df[i, :obs_event] = nrow(temp_event)

    end
    return df

end

function calculate_car(
    conn::Union{LibPQ.Connection, DBInterface.Connection},
    df::AbstractDataFrame,
    ff_est::FFEstMethod;
    date_start::String="dateStart",
    date_end::String="dateEnd",
    event_date::String="date",
    est_window_start::String="est_window_start",
    est_window_end::String="est_window_end",
    idcol::String="permno",
    suppress_warning::Bool=false
)
    df = copy(df)

    make_ff_est_windows!(df,
        ff_est;
        date_start,
        date_end,
        est_window_start,
        est_window_end,
        suppress_warning,
        event_date
    )
    
    temp = df[:, [idcol, est_window_start, est_window_end]]
    rename!(temp, est_window_start => date_start, est_window_end => date_end)
    temp = vcat(temp, df[:, [idcol, date_start, date_end]]) |> unique

    crsp_raw = crsp_data(conn, temp; date_start, date_end)
    ff_download = ff_data(
        conn;
        date_start=minimum(temp[:, date_start]),
        date_end=maximum(temp[:, date_end])
    )
    return calculate_car(
        (crsp_raw, ff_download),
        df,
        ff_est;
        date_start,
        date_end,
        idcol,
        suppress_warning=true
    )

end

function calculate_car(
    data::Tuple{DataFrame, DataFrame},
    df::AbstractDataFrame,
    ff_ests::Vector{FFEstMethod};
    date_start::String="dateStart",
    date_end::String="dateEnd",
    event_date::String="date",
    est_window_start::String="est_window_start",
    est_window_end::String="est_window_end",
    idcol::String="permno",
    suppress_warning::Bool=false
)
    df = copy(df)
    out = DataFrame()
    for ff_est in ff_ests
        temp = calculate_car(
            data,
            df,
            ff_est;
            date_start,
            date_end,
            est_window_start,
            est_window_end,
            idcol,
            event_date,
            suppress_warning
        )
        temp[!, :ff_method] .= repeat([ff_est], nrow(temp))
        if nrow(out) == 0
            out = temp[:, :]
        else
            out = vcat(out, temp)
        end
    end
    return out
end
