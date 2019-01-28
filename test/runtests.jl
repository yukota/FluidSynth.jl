using Test
using FluidSynth

@time @testset "Without an audio driver Test" begin include("without_audiodriver_test.jl") end
@time @testset "Midi file rendering Test" begin include("midifile_rendering_test.jl") end
# below test is need sound output.
# @time @testset "Audio driver Test" begin include("audiodriver_test.jl") end
# @time @testset "Midi file audio driver Test" begin include("midifile_play_test.jl") end
