# TITLE:	ProPer pre-preparation (I): Acoustics-to-Praat
# DESCRIPTION:  Process acoustic data from Praat for further analysis with R.
#         This script is the first part of the *ProPer* analysis toolbox:
#         "ProPer: PROsodic analysis with PERiodic energy" <https://osf.io/28ea5/>
#         (based on the *Mausmooth* Praat script by Francesco Cangemi:
#         https://ifl.phil-fak.uni-koeln.de/sites/linguistik/Phonetik/mitarbeiterdateien/fcangemi/mausmooth.praat)
# INPUT:	Audio files (preferably at 44.1 kHz sample-rate and 16 bit PCM).
# OUTPUT:	Pitch objects, pitch tiers and intensity tiers.
# NOTES:	This script creates the corresponding Praat objects (see "output") for 
#			files in the audio directory ("input"). The extracted parameters in 
#			the different Praat objects are used in the R code to yield periodic energy
#			and F0 time series. Select "inspect" to review and manually correct F0.
# IMPORTANT:	The script reads and writes files from a fixed folder structure
#			within the same directory as the script file itself. You can manually 
#			override these default locations in the path fields in the script below
#			or in the form that this script initiates.
#
# To Run:	Copy this text into a Praat script window (or simply double click the
#			file to directly open in a Praat script window) and run.

#####################
####### Input form
#####################

form Input parameters
    comment: "Change file paths below only if you need to override the default file locations"
    sentence: "InDirAudio", "audio/"
    comment: "Manually inspect F0 for corrections?"
    boolean: "inspect", "1"
    comment: "F0 path finder settings (adjustable)"
    integer: "pitchmax", "800"
    real: "voicingThr", "0.5"
    comment: "F0 smoothing bandwidth (Hz)"
    integer: "smooth", "12"
endform

Erase all

#####################
####### Settings
#####################

# ----- Create folders (if they do not exist) ----------------------

praat_dsp$ = "praat_dsp/"
createFolder: praat_dsp$

pitch_folder$ = praat_dsp$ + "pitch/"
createFolder: pitch_folder$

pitchtier_folder$ = praat_dsp$ + "pitchtier/"
createFolder: pitchtier_folder$

intensity_folder$ = praat_dsp$ + "intensity/"
createFolder: intensity_folder$

# ----- Logging ----------------------------------------------------

log_file$ = praat_dsp$ + "log.TableOfReal"
log_exists = fileReadable (log_file$)

if log_exists
    # Read exiting log
    log = Read from file: log_file$
else
    # Create log file
    log = Create TableOfReal: "log", 1, 1
    Save as text file: log_file$
endif

# ----- Get position -----------------------------------------------

# Get position of the next file to be inspected
position = Get value: 1, 1

# Load list of files
fileList = Create Strings as file list: "fileList", inDirAudio$ + "*.wav"
total_number_of_files = Get number of strings

# Check if all files have already been inspected
if position = total_number_of_files + 1
    beginPause: ""
        comment: "It seems that you have already inspected all files."
        comment: "Do you want to inspect everything again?"
    clicked = endPause: "Yes", "No", 1, 0
    if clicked == 1
        position = 0
    else
        select all
        Remove
        exitScript: ""
  endif
endif

counter = 0

if position > 0
    fileList = Extract part: position, total_number_of_files
    number_of_files = Get number of strings
    counter = position - 1
else
    number_of_files = total_number_of_files
endif

# ----- Iteration over pairs of audio and TextGrid -------------------------------

for i from 1 to number_of_files
    counter = counter + 1
    selectObject: fileList
    current_file$ = Get string: i
    name_prefix$ = current_file$ - ".wav"
    audio = Read from file: inDirAudio$ + current_file$

    # ----- Create IntensityTier -----
    To Intensity: 40, 0.001, "yes"
    Down to IntensityTier
    Save as short text file: intensity_folder$ + name_prefix$ + ".IntensityTier"

    # ----- Create raw Pitch -----
    selectObject: audio
    raw_pitch = To Pitch (raw autocorrelation): 0.001, 40, 800, 15, "yes", 0.03, 0.2, 0.02, 0.5, 0.14
    Save as short text file: pitch_folder$ + name_prefix$ + ".Pitch"

    # ----- Create filtered Pitch and PitchTier ----
    if inspect = 1

        # Open SoundEditor
	    selectObject: audio
        View & Edit

        # Create Pitch and open PitchEditor
        To Pitch (filtered autocorrelation): 0.001, 40, pitchmax, 15, "yes", 0.5, 0.09, voicingThr, 0.055, 0.35, 0.14
        View & Edit

        percent$ = fixed$ (((counter/total_number_of_files) * 100), 0)

        if counter == total_number_of_files
            beginPause: ""
                comment: "File " + string$ (counter) + " out of " + string$ (total_number_of_files) + " (" + percent$ + "% of files inspected)."
            clicked = endPause: "Stop here", "Conclude", 2, 1
            if clicked == 1
                selectObject: log
                Set value: 1, 1, counter
                Save as text file: log_file$
                select all
                Remove
                exitScript: ""
            endif
        else
            beginPause: ""
                comment: "File " + string$ (counter) + " out of " + string$ (total_number_of_files) + " (" + percent$ + "% of files inspected)."
            clicked = endPause: "Stop here", "Next file", 2, 1
            if clicked == 1
                selectObject: log
                Set value: 1, 1, counter
                Save as text file: log_file$
                select all
                Remove
                exitScript: ""
            endif
        endif
    elsif inspect = 0
        selectObject: sound
        To Pitch (filtered autocorrelation): 0.001, 40, pitchmax, 15, "yes", 0.5, 0.09, voicingThr, 0.055, 0.35, 0.14
    endif

    # Smooth Pitch object and create PitchTier of smoothed Pitch
    Smooth: smooth
    Down to PitchTier
    Save as short text file: pitchtier_folder$ + name_prefix$ + ".PitchTier"

    # ----- Update log file -----

    selectObject: log

    if counter == total_number_of_files
        Set value: 1, 1, counter + 1
    else
        Set value: 1, 1, counter
    endif

    Save as text file: log_file$

    # ----- Clear all objects of current iteration -----

    select all
    minusObject: fileList, log
    Remove

endfor

# ----- Clear everything -----
select all
Remove
