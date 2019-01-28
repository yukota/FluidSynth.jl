module FluidSynth

# Load shared lib
deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("fluidsynth not properly installed. Please run Pkg.build(\"fluidsynth\")")
end

export FLUID_OK, FLUID_FAILED,
    Settings, setstr, setint,
    Synth, sfload, program_select, noteoff, noteon, write_s16_stereo, write_s16, write_float, set_gain, set_sample_rate,
    Player, add, play, stop, join, get_status,
    PlayerStatus, Playing, Ready, Done,
    FileRenderer, process_block,
    AudioDriver

const FLUID_OK = 0
const FLUID_FAILED = -1

mutable struct Settings
    settings_ptr::Ptr{Cvoid}

    function Settings()
 		settings = new(C_NULL)
    settings.settings_ptr = ccall((:new_fluid_settings, libfluidsynth), Ptr{Cvoid}, ())
    finalizer(settings) do settings
    ccall((:delete_fluid_settings, libfluidsynth), Cvoid, (Ptr{Cvoid},), settings.settings_ptr)
    end
    settings
    end
end

function setstr(settings::Settings, name::String, str::String)
    ret = ccall((:fluid_settings_setstr, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cstring), settings.settings_ptr, name, str)
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
    ret
end

function setint(settings::Settings, name::String, val::Int32)
    ret = ccall((:fluid_settings_setint, libfluidsynth), Cint, (Ptr{Cvoid}, Cstring, Cint), settings.settings_ptr, name, val)
    if ret == FLUID_FAILED
    throw(ErrorException("fail setint"))
    end
    ret
end

mutable struct Synth
    synth_ptr::Ptr{Cvoid}
    settings::Settings

    function Synth(settings::Settings)
    synth = new(C_NULL, settings)

    synth.synth_ptr = ccall((:new_fluid_synth, libfluidsynth), Ptr{Cvoid}, (Ptr{Cvoid},), settings.settings_ptr)
    finalizer(synth) do synth
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
end

function set_gain(synth::Synth, gain::Float32)
    ccall((:fluid_synth_set_gain, libfluidsynth), Cvoid, (Ptr{Cvoid}, Cfloat), synth.synth_ptr, gain)
end

function set_sample_rate(synth::Synth, sample_rate::Float32)
    ccall((:fluid_synth_set_gain, libfluidsynth), Cvoid, (Ptr{Cvoid}, Cfloat), synth.synth_ptr, sample_rate)
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
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
end

function write_float(synth::Synth, len::Int32, lout::Vector{Float32}, loff::Int32, lincr::Int32, rout::Vector{Float32}, roff::Int32, rincr::Int32)
    ret = ccall((:fluid_synth_write_float, libfluidsynth),
    Cint,
    (Ptr{Cvoid}, Cint, Ptr{Cvoid}, Cint, Cint, Ptr{Cvoid}, Cint, Cint),
    synth.synth_ptr, len, lout, loff, lincr, rout, roff, rincr)
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
end

# player
mutable struct Player
    player_ptr::Ptr{Cvoid}
    synth::Synth

    function Player(synth::Synth)
 		player = new(C_NULL, synth)
    player.player_ptr = ccall((:new_fluid_player, libfluidsynth), Ptr{Cvoid}, (Ptr{Cvoid},), synth.synth_ptr)
    finalizer(player) do player
    ccall((:delete_fluid_player, libfluidsynth), Cvoid, (Ptr{Cvoid},), player.player_ptr)
    end
    player
    end
end

"""
Add a MIDI file to a player queue.
"""
function add(player::Player, midifile::String)
    ret = ccall((:fluid_player_add, libfluidsynth),
    Cint,
    (Ptr{Cvoid}, Cstring),
    player.player_ptr, midifile)
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
end

function play(player::Player)
    ret = ccall((:fluid_player_play, libfluidsynth),
    Cint,
    (Ptr{Cvoid}, ),
    player.player_ptr)
    if ret == FLUID_FAILED
    throw(ErrorException(""))
    end
end

function stop(player::Player)
    ccall((:fluid_player_stop, libfluidsynth),
    Cint,
    (Ptr{Cvoid}, ),
    player.player_ptr)
    # this metod always reutrn ok.
end

function join(player::Player)
    ret = ccall((:fluid_player_join, libfluidsynth),
    Cint,
    (Ptr{Cvoid}, ),
    player.player_ptr)
    # this metod always reutrn ok.
end

@enum PlayerStatus begin
    Ready = 0
    Playing = 1
    Done = 2
end

function get_status(player::Player)
    ret = ccall((:fluid_player_get_status, libfluidsynth), Cint, (Ptr{Cvoid},), player.player_ptr)
    if ret == Int(Ready::PlayerStatus)
    return Ready::PlayerStatus
    elseif ret == Int(Playing::PlayerStatus)
    return Playing::PlayerStatus
    else
    return Done::PlayerStatus
    end

end

# file renderer
mutable struct FileRenderer

    ptr::Ptr{Cvoid}
    synth::Synth

    function FileRenderer(synth::Synth)
    file_renderer = new(C_NULL, synth)

    file_renderer.ptr = ccall((:new_fluid_file_renderer, libfluidsynth), Ptr{Cvoid}, (Ptr{Cvoid},), synth.synth_ptr)
    finalizer(file_renderer) do file_renderer
    ccall((:delete_fluid_file_renderer, libfluidsynth), Cvoid, (Ptr{Cvoid},), file_renderer.ptr)
    end
    file_renderer
    end
end

function process_block(file_renderer::FileRenderer)
    ccall((:fluid_file_renderer_process_block, libfluidsynth), Cint, (Ptr{Cvoid},), file_renderer.ptr)
end


# file renderer
mutable struct AudioDriver

    ptr::Ptr{Cvoid}
    settings::Settings
    synth::Synth

    function AudioDriver(settings::Settings, synth::Synth)
    audio_driver = new(C_NULL, settings, synth)

    audio_driver.ptr = ccall((:new_fluid_audio_driver, libfluidsynth), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), settings.settings_ptr, synth.synth_ptr)
    finalizer(audio_driver) do audio_driver
        ccall((:delete_fluid_audio_driver, libfluidsynth), Cvoid, (Ptr{Cvoid},), audio_driver.ptr)
    end
    audio_driver
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
