const ALPHABET = join('a':'z')

function choose_grid_layout(num_plots, cols, rows)
    if isnothing(cols) && isnothing(rows)
        cols = ceil(Int64, sqrt(num_plots))
        rows = ceil(Int64, num_plots / cols)
    elseif isnothing(cols)
        cols = ceil(Int64, num_plots / rows)
    elseif isnothing(rows)
        rows = ceil(Int64, num_plots / cols)
    end
    plot_positions = vec([(j, i) for i in 1:cols, j in 1:rows])
    return rows, cols, plot_positions
end

function plot_profile!(prof::ProfileLikelihoodSolutionView, fig, ℓ, k, i, j,
    spline, true_vals, mle_val=nothing, shade_ci=true, param_name=LaTeXStrings.L"\theta_{%$ℓ}"; axis_kwargs=nothing)
    lower_ci, upper_ci = get_confidence_intervals(prof)
    θ_vals = get_parameter_values(prof)
    ℓ_vals = get_profile_values(prof)
    conf_level = get_level(get_confidence_intervals(prof))
    threshold = get_chisq_threshold(conf_level)
    formatted_conf_level = parse(Float64, Printf.format(Printf.Format("%.2g"), 100conf_level))
    formatted_lower_ci = parse(Float64, Printf.format(Printf.Format("%.3g"), lower_ci))
    formatted_upper_ci = parse(Float64, Printf.format(Printf.Format("%.3g"), upper_ci)) # This is what @sprintf is doing, but we need to do this so that we can extract the returned value to inteprolate into LaTeXStrings
    if axis_kwargs !== nothing
        ax = CairoMakie.Axis(fig[i, j],
            xlabel=param_name,
            ylabel=LaTeXStrings.L"$\ell_p^*($%$(param_name)$) - \ell^*$",
            title=LaTeXStrings.L"(%$(ALPHABET[ℓ])): $%$formatted_conf_level$% CI: $(%$formatted_lower_ci, %$formatted_upper_ci)$",
            titlealign=:left; axis_kwargs...)
    else
        ax = CairoMakie.Axis(fig[i, j],
            xlabel=param_name,
            ylabel=LaTeXStrings.L"$\ell_p^*($%$(param_name)$) - \ell^*$",
            title=LaTeXStrings.L"(%$(ALPHABET[ℓ])): $%$formatted_conf_level$% CI: $(%$formatted_lower_ci, %$formatted_upper_ci)$",
            titlealign=:left)
    end
    CairoMakie.ylims!(ax, threshold - 1, 0.1)
    if !spline
        CairoMakie.lines!(ax, θ_vals, ℓ_vals)
        CairoMakie.hlines!(ax, [threshold], color=:red, linetype=:dashed)
        CI_range = lower_ci .< θ_vals .< upper_ci
        shade_ci && CairoMakie.band!(ax, θ_vals[CI_range], ℓ_vals[CI_range], repeat([threshold], count(CI_range)), color=(:blue, 0.35))
    else
        val_range = extrema(θ_vals)
        Δθ₁ = (val_range[2] - val_range[1]) / max(length(θ_vals), 1000)
        data_vals = val_range[1]:Δθ₁:val_range[2]
        CairoMakie.lines!(ax, data_vals, prof(data_vals))
        CairoMakie.hlines!(ax, [threshold], color=:red, linetype=:dashed)
        Δθ₂ = (upper_ci - lower_ci) / max(length(θ_vals), 1000)
        if Δθ₂ ≠ 0.0
            ci_vals = lower_ci:Δθ₂:upper_ci
            shade_ci && CairoMakie.band!(ax, ci_vals, prof(ci_vals), repeat([threshold], length(ci_vals)), color=(:blue, 0.35))
        end
    end
    if !isnothing(true_vals)
        CairoMakie.vlines!(ax, [true_vals], color=:black, linetype=:dashed)
    end
    if !isnothing(mle_val)
        CairoMakie.vlines!(ax, [mle_val], color=:red, linetype=:dashed)
    end
    return nothing
end
function plot_profile!(prof::BivariateProfileLikelihoodSolutionView, fig, ℓ, (k, r), i, j,
    true_vals, interpolation=false, smooth_confidence_boundary=false, mle_val=nothing, (name_1, name_2)=(L"\psi", L"\varphi"), close_contour=true; axis_kwargs=nothing)
    if !interpolation
        grid_1 = get_parameter_values(prof, 1).parent
        grid_2 = get_parameter_values(prof, 2).parent
        prof_vals = get_profile_values(prof).parent
    else
        grid_1 = get_parameter_values(prof, 1).parent
        grid_2 = get_parameter_values(prof, 2).parent
        grid_1 = LinRange(extrema(grid_1)..., 12length(grid_1))
        grid_2 = LinRange(extrema(grid_2)..., 12length(grid_2))
        prof_vals = [prof(x, y) for x in grid_1, y in grid_2]
    end
    if axis_kwargs !== nothing
        ax = CairoMakie.Axis(fig[i, j],
            xlabel=L"%$(name_1)",
            ylabel=L"%$(name_2)",
            title=LaTeXStrings.L"(%$(ALPHABET[ℓ])): $(%$(name_1), %$(name_2))$",
            titlealign=:left; axis_kwargs...)
    else
        ax = CairoMakie.Axis(fig[i, j],
            xlabel=L"%$(name_1)",
            ylabel=L"%$(name_2)",
            title=LaTeXStrings.L"(%$(ALPHABET[ℓ])): $(%$(name_1), %$(name_2))$",
            titlealign=:left)
    end
    conf = get_confidence_regions(prof)
    conf_x = conf.x
    conf_y = conf.y
    CairoMakie.heatmap!(ax, grid_1, grid_2, prof_vals, colorrange=(-16, 0))
    if !smooth_confidence_boundary
        if close_contour
            CairoMakie.lines!(ax, [conf_x..., conf_x[begin]], [conf_y..., conf_y[begin]], color=:red, linewidth=3)
        else
            CairoMakie.lines!(ax, conf_x, conf_y, color=:red, linewidth=3)
        end
    else
        A = [conf_x conf_y]
        itp = Interpolations.scale(interpolate(A, (BSpline(Cubic(Natural(OnGrid()))), NoInterp())), LinRange(0, 1, length(conf_x)), 1:2)
        finer_t = LinRange(0, 1, 6length(conf_x))
        xs, ys = [itp(t, 1) for t in finer_t], [itp(t, 2) for t in finer_t]
        if close_contour
            CairoMakie.lines!(ax, [xs..., xs[begin]], [ys..., ys[begin]], color=:red, linewidth=3)
        else
            CairoMakie.lines!(ax, xs, ys, color=:red, linewidth=3)
        end
    end
    if !isnothing(true_vals) && (!isnothing(true_vals[1]) && !isnothing(true_vals[2]))
        CairoMakie.scatter!(ax, [true_vals[1]], [true_vals[2]], color=:black, markersize=12)
    end
    if !isnothing(mle_val)
        CairoMakie.scatter!(ax, [mle_val[1]], [mle_val[2]], color=:red, markersize=12)
    end
    return nothing
end

SciMLBase.sym_to_index(vars::Integer, prof::ProfileLikelihoodSolution) = vars

"""
    plot_profiles(prof::ProfileLikelihoodSolution, vars = profiled_parameters(prof); 
        ncol=nothing, 
        nrow=nothing,
        true_vals=Dict(vars .=> nothing), 
        spline=true, 
        show_mles=true, 
        shade_ci=true, 
        fig_kwargs=nothing, 
        axis_kwargs=nothing,
        latex_names = Dict(vars .=> [LaTeXStrings.L"\theta_{i}" for i in SciMLBase.sym_to_index.(vars, Ref(prof))])) 
     
Plot results from a profile likelihood solution `prof`.

# Arguments 
- `prof::ProfileLikelihoodSolution`: The profile likelihood solution from [`profile`](@ref).
- `vars = profiled_parameters(prof)`: The parameters to plot.

# Keyword Arguments 
- `ncol=nothing`: The number of columns to use. If `nothing`, chosen automatically via `choose_grid_layout`.
- `nrow=nothing`: The number of rows to use. If `nothing`, chosen automatically via `choose_grid_layout`
- `true_vals=Dict(vars .=> nothing)`: A dictionary mapping parameter indices to their true values, if they exist. If `nothing`, nothing is plotted, otherwise a black line is plotted at the true value for the profile. 
- `spline=true`: Whether the curve plotted should come from a spline through the results, or if the data itself should be plotted. 
- `show_mles=true`: Whether to put a red line at the MLEs. 
- `shade_ci=true`: Whether to shade the area under the profile between the confidence interval.
- `fig_kwargs=nothing`: Extra keyword arguments for `Figure` (see the Makie docs).
- `axis_kwargs=nothing`: Extra keyword arguments for `Axis` (see the Makie docs).
- `latex_names = Dict(vars .=> [LaTeXStrings.L"\theta_{i}" for i in SciMLBase.sym_to_index.(vars, Ref(prof))]))`: LaTeX names to use for the parameters. Defaults to `θᵢ`, where `i` is the index of the parameter. 

# Output 
The `Figure()` is returned.
"""
function plot_profiles(prof::ProfileLikelihoodSolution, vars=profiled_parameters(prof);
    ncol=nothing,
    nrow=nothing,
    true_vals=Dict(vars .=> nothing),
    spline=true,
    show_mles=true,
    shade_ci=true,
    fig_kwargs=nothing,
    axis_kwargs=nothing,
    latex_names=Dict(vars .=> [LaTeXStrings.L"\theta_{%$i}" for i in SciMLBase.sym_to_index.(vars, Ref(prof))]))
    num_plots = vars isa Symbol ? 1 : length(vars)
    _, _, plot_positions = choose_grid_layout(num_plots, ncol, nrow)
    if fig_kwargs !== nothing
        fig = CairoMakie.Figure(; fig_kwargs...)
    else
        fig = CairoMakie.Figure()
    end
    itr = vars isa Symbol ? [(1, vars)] : pairs(vars)
    for (ℓ, k) in itr
        i, j = plot_positions[ℓ]
        if axis_kwargs !== nothing
            plot_profile!(prof[k], fig, ℓ, k, i, j, spline, true_vals[k], show_mles ? get_likelihood_solution(prof)[k] : nothing, shade_ci, latex_names[k]; axis_kwargs)
        else
            plot_profile!(prof[k], fig, ℓ, k, i, j, spline, true_vals[k], show_mles ? get_likelihood_solution(prof)[k] : nothing, shade_ci, latex_names[k])
        end
    end
    return fig
end



function plot_profiles(prof::BivariateProfileLikelihoodSolution, vars=profiled_parameters(prof);
    ncol=nothing,
    nrow=nothing,
    true_vals=Dict(1:number_of_parameters(get_likelihood_problem(prof)) .=> nothing),
    show_mles=true,
    fig_kwargs=nothing,
    axis_kwargs=nothing,
    interpolation=false,
    smooth_confidence_boundary=false,
    close_contour=true,
    latex_names=Dict(1:number_of_parameters(get_likelihood_problem(prof)) .=> get_syms(prof)))
    num_plots = (vars isa NTuple{2,Symbol} || vars isa NTuple{2,Int64}) ? 1 : length(vars)
    nr, nc, plot_positions = choose_grid_layout(num_plots, ncol, nrow)
    if fig_kwargs !== nothing
        fig = CairoMakie.Figure(; fig_kwargs...)
    else
        fig = CairoMakie.Figure()
    end
    itr = (vars isa NTuple{2,Symbol} || vars isa NTuple{2,Int64}) ? [(1, Tuple(vars))] : pairs(vars)
    for (ℓ, (k, r)) in itr
        i, j = plot_positions[ℓ]
        if axis_kwargs !== nothing
            __plot_profile!(prof[k, r], fig, ℓ, (k, r), i, j, (true_vals[k], true_vals[r]), interpolation, smooth_confidence_boundary, show_mles ? (get_likelihood_solution(prof)[k], get_likelihood_solution(prof)[r]) : nothing, (latex_names[k], latex_names[r]), close_contour; axis_kwargs)
        else
            __plot_profile!(prof[k, r], fig, ℓ, (k, r), i, j, (true_vals[k], true_vals[r]), interpolation, smooth_confidence_boundary, show_mles ? (get_likelihood_solution(prof)[k], get_likelihood_solution(prof)[r]) : nothing, (latex_names[k], latex_names[r]), close_contour)
        end
    end
    Colorbar(fig[1:nr, nc+1], colorrange=(-16, 0), colormap=:viridis, label=L"Normalised profile $ $", ticks=(-16:4:0))
    return fig
end