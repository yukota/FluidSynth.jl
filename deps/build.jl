using BinDeps

@BinDeps.setup

fluidsynth = library_dependency("fluidsynth", aliases=["libfluidsynth"])

provides(AptGet, "libfluidsynth-dev", fluidsynth)

@static if Sys.isapple()
    using Homebrew
    provides(Homebrew.HB, "fluid-synth", fluidsynth, os = :Darwin)
end

@BinDeps.install Dict(:fluidsynth => :libfluidsynth)
