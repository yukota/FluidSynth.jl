# This test use audio device.
# Don't add runtests.jl

using fluidsynth

synth = Synth()

# use default sound audio
start_audio_driver(synth, "pulseaudio")

sfont_id = sfload(synth, "violin_sample.sf2")
program_select(synth, Int32(0), sfont_id, Int32(0), Int32(0))

noteon(synth, Int32(0), Int32(60), Int32(70))
# wait 3 second to lesten sound
sleep(3)
