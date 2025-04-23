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
#			pitch objects and intensity tiers are used in the R code to yield 
#			periodic energy and F0 time series. To adjust the F0 path finding 
#			algorithm in Praat without affecting the periodic energy measurement
#			it is advised to only change the parameters in the fields of this 
#			script's form. Select "inspect" to review and manually correct F0.
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

## create pitch object (to extract the periodic data)
	selectObject: "Sound 'name_prefix$'"
		To Pitch (raw autocorrelation): 0.001, 40, 800, 15, "yes", 0.03, 0.2, 0.02, 0.5, 0.14
		Save as short text file: "'OutDirPitchObject$''name_prefix$'.Pitch"	
		Remove

## create pitch tier (manually inspect files if selected)
if inspect = 1
	selectObject: "Sound 'name_prefix$'"
		View & Edit
		To Pitch (filtered autocorrelation): 0.001, 40, pitchmax, 15, "yes", 0.5, 0.09, voicingThr, 0.055, 0.35, 0.14
		View & Edit
		pause Confirm
elsif inspect = 0
	selectObject: "Sound 'name_prefix$'"
		To Pitch (filtered autocorrelation): 0.001, 40, pitchmax, 15, "yes", 0.5, 0.09, voicingThr, 0.055, 0.35, 0.14
endif
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