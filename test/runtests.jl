using fluidsynth
using Plots

gr()

synth = Synth()

noteon(synth, Int32(0), Int32(60), Int32(70))
wav = write_s16_stereo(synth, Int32(1024))

noteoff(synth, Int32(0), Int32(60))

del(synth)

print(length(wav))
x = 1:length(wav)
#plot(x, wav, marker=:circle)
plot(rand(4,4))
# check wav;
gui()
