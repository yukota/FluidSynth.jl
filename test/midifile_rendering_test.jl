using Test

using fluidsynth

synth = Synth()

settings = Settings()
setstr(settings, "audio.file.name", "test_result.wav")
setstr(settings, "player.timing-source", "sample")
setint(settings, "synth.lock-memory", Int32(0));

synth = Synth(settings)
sfont_id = sfload(synth, "violin_sample.sf2")
program_select(synth, Int32(0), sfont_id, Int32(0), Int32(0))


player = Player(synth)
add(player, "test.mid")
play(player)

file_renderer = FileRenderer(synth)
while get_status(player) == Playing
    if process_block(file_renderer) != FLUID_OK
        break
    end
end

stop(player)
fluidsynth.join(player)
