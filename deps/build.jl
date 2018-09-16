using BinDeps

@BinDeps.setup

fluidsynth = library_dependency("libfluidsynth", aliases=["libfluidsynth.so.1"])

provides(AptGet, Dict("libfluidsynth-dev" => fluidsynth))

@BinDeps.install Dict(:libfluidsynth => :libfluidsynth)
