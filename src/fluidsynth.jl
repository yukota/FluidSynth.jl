module fluidsynth

# Load shared lib
deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("fluidsynth not properly installed. Please run Pkg.build(\"fluidsynth\")")
end

export Synth, sfload, program_select, noteoff, noteon, write_s16_stereo

const FLUDI_OK = 0
const FLUID_NG = -1

mutable struct Synth
    synth_ptr::Ptr{Cvoid}
    setting_ptr::Ptr{Cvoid}

    function Synth(gain=0.2, samplerate=44100, channels=256)

        # settings
        synth = new(C_NULL, C_NULL)
	    synth.setting_ptr = ccall((:new_fluid_settings, libfluidsynth), Ptr{Cvoid}, ())
        # set setting parameters
        ccall((:fluid_settings_setstr, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cstring), synth.setting_ptr, "synth.gain", string(gain))
        ccall((:fluid_settings_setstr, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cstring), synth.setting_ptr, "synth.sample-rate", string(samplerate))
        ccall((:fluid_settings_setstr, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cstring), synth.setting_ptr, "synth.midi-channels", string(channels))

        # create synth
	    synth.synth_ptr = ccall((:new_fluid_synth, libfluidsynth), Ptr{Cvoid}, (Ptr{Cvoid},), synth.setting_ptr)

		finalizer(synth) do synth
			ccall((:delete_fluid_settings, libfluidsynth), Cvoid, (Ptr{Cvoid},), synth.setting_ptr)
			ccall((:delete_fluid_synth, libfluidsynth), Cvoid, (Ptr{Cvoid},), synth.synth_ptr)
		end

 	    synth
    end
end

# fluidsynth interfaces.
"""
Load SoundFont file.
Return SoundFont ID.

# Arguments
- `filename` : path to SoundFont file.
- `reset_presets` : true to re-assign presets for all MIDI channels
"""
function sfload(synth::Synth, filename::AbstractString, reset_presets=false::Bool)
	c_reset_preset = 0
	if reset_presets
		c_reset_preset = 1
	end
    ret = ccall((:fluid_synth_sfload, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cint), synth.synth_ptr, filename, c_reset_preset);
	if ret == FLUID_NG
		throw(ErrorException())
	end
    ret
end

"""
Select an instrument on a MIDI channel by SoundFont ID, bank and program numbers.
# Arguments
- `chan` : MIDI channel number
- `sfont_id` : ID of loaded SoundFont
- `bank_num` : MIDI bank number
- `preset_num` : MIDI program number
"""
function program_select(synth::Synth, chan::Int32, sfont_id::Int32, bank_num::Int32, preset_num::Int32)
    ret = ccall((:fluid_synth_program_select, libfluidsynth), Cint, (Ptr{Cvoid}, Cint, Cint, Cint, Cint), synth.synth_ptr, chan, sfont_id, bank_num, preset_num)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

"""
Send a note-on event.
# Arguments
- `chan` : MIDI channel number(0-127)
- `key` : MIDI note number(0-127)
- `vel` : MIDI velocity(0-127, 0=noteoff)
"""
function noteon(synth::Synth, chan::Int32, key::Int32, vel::Int32)
    ret = ccall((:fluid_synth_noteon, libfluidsynth), Cint, (Ptr{Cvoid}, Cint, Cint, Cint), synth.synth_ptr, chan, key, vel)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

"""
Send a note-off event.
# Arguments
- `chan` : MIDI channel number(0-127)
- `key` : MIDI note number(0-127)
"""
function noteoff(synth::Synth, chan::Int32, key::Int32)
    ret = ccall((:fluid_synth_noteoff, libfluidsynth), Cint, (Ptr{Cvoid}, Cint, Cint), synth.synth_ptr, chan, key)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

"""
Set the MIDI pitch bend controller value on a MIDI channel.
# Arguments
- `chan` : MIDI channel number(0-127)
- `val` : MIDI pitch bend value(0-16383 with 8192 being center)
"""
function pitch_bend(synth::Synth, chan::Int32, val::Int32)
    ret = ccall((:fluid_synth_pitch_bend, libfluidsynth), Cint, (Ptr{Cvoid}, Cint, Cint), synth.synth_ptr, chan, val)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

"""
Send a MIDI controller event on a MIDI channel.
# Arguments
- `chan` : MIDI channel number(0-127)
- `num` : MIDI controller number(0-127)
- `val` : MIDI controller value(0-127)
"""
function cc(synth::Synth, chan::Int32, num::Int32, val::Int32)
    ret = ccall((:fluid_synth_cc, libfluidsynth), Cint, (Ptr{Cvoid}, Cint, Cint, Cint), synth.synth_ptr, chan, num, val)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

"""
Synthesize a block of 16 bit audio samples to audio buffers.
# Arguments
- `len` : Count of audio frames to synthesize
- `lout::Vector{Int16}` : Vector of signed 16 bit to store left channel of audio
- `loff` : Offset index in 'lout' for first sample
- `lincr` : Increment between samples stored to 'lout'.
- `rout::Vector{Int16}` : Vector of signed 16 bit to store right channel of audio
- `roff` : Offset index in 'rout' for first sample
- `rincr` : Increment between samples stored to 'rout'.
"""
function write_s16(synth::Synth, len::Int32, lout::Vector{Int16}, loff::Int32, lincr::Int32, rout::Vector{Int16}, roff::Int32, rincr::Int32)
    ret = ccall((:fluid_synth_write_s16, libfluidsynth),
		Cint,
		(Ptr{Cvoid}, Cint, Ptr{Cvoid}, Cint, Cint, Ptr{Cvoid}, Cint, Cint),
		synth.synth_ptr, len, lout, loff, lincr, rout, roff, rincr)
	if ret == FLUID_NG
		throw(ErrorException())
	end
end

# support methods
"""
Synthesize a 16 bit stereo audio samples.
Retuen synthesized vector. vector size is 2 * len(Because of stereo).
# Arguments
- `len::Int32` : Count of audio frames to synthesize.
"""
function write_s16_stereo(synth::Synth, len::Int32)
    buf = Vector{Int16}(undef, 2 * len)
    write_s16(synth, len, buf, Int32(0) , Int32(2), buf, Int32(1), Int32(2))
    return buf
end

end # module
