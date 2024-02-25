# TITLE:	ProPer pre-preparation (I): Acoustics-to-Praat
#   Extract acoustic data from Praat for further analysis with R 
#   (see following files in workflow).
# INPUT:	Audio files (preferably at 44.1 kHz sample-rate and 16 bit PCM).
# OUTPUT:	Pitch objects, pitch tiers and intensity tiers.
# NOTES:	This script creates the corresponding Praat objects (see "output") for 
#		files in the audio directory ("input"). The extracted parameters in 
#		pitch objects and intensity tiers are used in the R code to yield 
#		periodic energy curves. The pitch tier object is used for standard 
#		F0 information, which can be tweaked in fields of this script's form, 
#		and can be manually corrected when the "inspect" option is switched on.
# IMPORTANT:	The script reads and writes files from a fixed folder structure
#   within the same directory as the script file itself. You can manually 
#   override these default locations in the path fields in the script below
#   or in the form that this script initiates.
#
# AUTHORS:	Aviad Albert and Francesco Cangemi {a.albert / fcangemi} @uni-koeln.de
#
# To Run:   Copy this text into a Praat script window (or simply double click the
#   file to directly open in a Praat script window) and run.

####### Input form
form Input parameters
        comment Change file paths below only if you need to override the default file locations
        # comment Note your platform's syntax: PC directories are often "C:\...\"; Mac 
        # comment directories are often "/Users/.../".
        # comment Do not forget the final slash!
        sentence InDirAudio audio/
        sentence OutDirPitchObject	praat_data/pitch_objects/
        sentence OutDirPitchTier praat_data/pitch_tiers/
        sentence OutDirIntensityTier praat_data/intensity_tiers/
        comment Manually inspect F0 for corrections?
        boolean inspect 1
        comment F0 path finder settings (adjustable).
        real silenceThr 0.03
        real voicingThr 0.4
        real octave 0.02
        real octavejump 0.5
        real voiceunvoiced 0.14
        integer pitchmax 600
        comment F0 smoothing bandwidth (Hz).
        integer smooth 10
endform
Erase all

####### Settings
## list files
Create Strings as file list: "soundFileObj",  "'InDirAudio$'*.wav"
number_of_files = Get number of strings
for i from 1 to number_of_files
	selectObject: "Strings soundFileObj"
	current_file$ = Get string: 'i'
	name_prefix$ = current_file$ - ".wav"

## create intensity tiers
	Read from file: "'InDirAudio$''current_file$'"
		To Intensity: 40, 0.001, "yes"
		Down to IntensityTier
		Save as short text file: "'OutDirIntensityTier$''name_prefix$'.IntensityTier"
		Remove
		selectObject: "Intensity 'name_prefix$'"
		Remove

## create pitch object and tier (manually inspect files if selected)
if inspect = 1
	selectObject: "Sound 'name_prefix$'"
		View & Edit
		To Pitch (ac): 0.001, 40, 15, "yes", silenceThr,
           ...voicingThr, octave, octavejump, voiceunvoiced, pitchmax
		View & Edit
		pause Confirm
elsif inspect = 0
	selectObject: "Sound 'name_prefix$'"
		To Pitch (ac): 0.001, 40, 15, "yes", silenceThr,
           ...voicingThr, octave, octavejump, voiceunvoiced, pitchmax
endif
		Save as short text file: "'OutDirPitchObject$''name_prefix$'.Pitch"	
		Smooth: smooth
		Down to PitchTier
		Save as short text file: "'OutDirPitchTier$''name_prefix$'.PitchTier"
		Remove

## finish and clear  
  select all
    minusObject: "Strings soundFileObj"
    Remove

endfor
select all
Remove
