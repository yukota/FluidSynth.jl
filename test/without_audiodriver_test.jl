using Test

using FluidSynth

settings = Settings()
synth = Synth(settings)

sfont_id = sfload(synth, "violin_sample.sf2")
program_select(synth, Int32(0), sfont_id, Int32(0), Int32(0))
noteon(synth, Int32(0), Int32(60), Int32(70))
wav = write_s16_stereo(synth, Int32(1024))
@test length(wav) == 2048
