using Test

using FluidSynth

settings = Settings()
setstr(settings, "audio.driver", "pulseaudio")

synth = Synth(settings)
sfload(synth, "violin_sample.sf2")

player = Player(synth)
audio_driver = AudioDriver(settings, synth)


add(player, "test.mid")
play(player)

FluidSynth.join(player)
