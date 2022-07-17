using Test
using CairoMakie

using ProfileLikelihood


include("template_functions.jl")
@testset "Regression" begin
    include("regression.jl")
end
@testset "Linear exponential ODE" begin
    include("linear_exponential_ode.jl")
end
@testset "Logistic ODE" begin
    include("logistic_ode.jl")
end
@testset "Transforming results" begin
    include("transforms.jl")
end
@testset "General tests" begin
    include("general.jl")
end
@testset "Refinement" begin
    include("refinement.jl")
end
@testset "Scaling" begin 
    include("scaling.jl")
end