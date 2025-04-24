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
      comment Change file paths below only if you need to override the default file locations
        sentence InDirAudio audio/
        sentence OutDirPitchObject	praat_data/pitch_objects/
        sentence OutDirPitchTier praat_data/pitch_tiers/
        sentence OutDirIntensityTier praat_data/intensity_tiers/
      comment Manually inspect F0 for corrections?
        boolean inspect 1
      comment F0 path finder settings (adjustable)
        integer pitchmax 800
        real voicingThr 0.5
      comment F0 smoothing bandwidth (Hz)
        integer smooth 12
endform
Erase all


#####################
####### Settings
#####################

log_file$ = "praat_data/log.TableOfReal"
log_exists = fileReadable (log_file$)

if log_exists
    log = Read from file: log_file$
else
    log = Create TableOfReal: "log", 1, 1
    Save as text file: log_file$
endif

position = Get value: 1, 1

fileList = Create Strings as file list: "soundFileObj",  "'InDirAudio$'*.wav"
total_number_of_files = Get number of strings
number_of_files = total_number_of_files

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
endif

for i from 1 to number_of_files
    counter = counter + 1
    selectObject: fileList
    current_file$ = Get string: i
    name_prefix$ = current_file$ - ".wav"

    ## create intensity tiers
    Read from file: "'InDirAudio$''current_file$'"
    To Intensity: 40, 0.001, "yes"
    Down to IntensityTier
    Save as short text file: "'OutDirIntensityTier$''name_prefix$'.IntensityTier"
    Remove
    selectObject: "Intensity 'name_prefix$'"
    Remove

    ## create pitch object (to extract the periodic data)
	selectObject: "Sound 'name_prefix$'"
    To Pitch (raw autocorrelation): 0.001, 40, 800, 15, "yes", 0.03, 0.2, 0.02, 0.5, 0.14
    Save as short text file: "'OutDirPitchObject$''name_prefix$'.Pitch"	
    Remove

    ## create pitch object and tier (manually inspect files if selected)
    if inspect = 1
	    selectObject: "Sound 'name_prefix$'"
        View & Edit
        @getFilteredPitch
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
        selectObject: "Sound 'name_prefix$'"
        @getFilteredPitch
    endif

    Smooth: smooth
    Down to PitchTier
    Save as short text file: "'OutDirPitchTier$''name_prefix$'.PitchTier"
    Remove

    selectObject: log

    if counter == total_number_of_files
        Set value: 1, 1, counter + 1
    else
        Set value: 1, 1, counter
    endif

    Save as text file: log_file$

    ## finish and clear  
    select all
    minusObject: fileList, log
    Remove
endfor

procedure getFilteredPitch
    To Pitch (filtered autocorrelation): 0.001, 40, pitchmax, 15, "yes", 0.5, 0.09, voicingThr, 0.055, 0.35, 0.14
endproc

select all
Remove

