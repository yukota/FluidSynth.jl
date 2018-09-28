using BinDeps

@BinDeps.setup

fluidsynth = library_dependency("fluidsynth", aliases=["libfluidsynth.so"])

provides(AptGet, Dict("libfluidsynth-dev" => fluidsynth))

@BinDeps.install Dict(:fluidsynth => :libfluidsynth)
