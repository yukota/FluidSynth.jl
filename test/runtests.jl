using Test
using fluidsynth

@time @testset "Without an audio driver Test" begin include("without_audiodriver_test.jl") end
