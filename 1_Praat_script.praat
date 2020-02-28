# TITLE:	Praat's Periodic Power (PPP)
# INPUT:	Audio files (preferably at least 44.1kHz sample-rate and 16bit PCM).
# OUTPUT:	Pitch objects, pitch tiers and intensity tiers.
# NOTES:	This script creates the corresponding Praat objects (see "output") for 
#		files in the audio directory ("input"). The extracted parameters in 
#		pitch objects and intensity tiers are used in the R code to yield 
#		periodic energy curves. The pitch tier object is used for standard 
#		F0 information, which can be tweaked in fields of this script's form, 
#		and can be manually corrected when the "inspect" option is switched on.
#IMPORTANT:	Before running the script, make sure to replace the 'xxx' in the 
#		directories with your relevant directory string (either in the script 
#		or in the prompted form). Also, make sure that your audio files are in 
#		the "Audio" directory.
# AUTHORS:	Aviad Albert and Francesco Cangemi {a.albert / fcangemi} @uni-koeln.de

####### Input form Tobias
form Input parameters
        comment Replace "xxx" with your diretories info. Note your platform's syntax:
        comment PC directories are often "C:\...\"; Mac directories are often "/Users/.../".
        # comment Do not forget the final slash!
        sentence InDirAudio xxx/audio/
        sentence OutDirPitchObject	xxx/praat_data/pitch_objects/
        sentence OutDirPitchTier xxx/praat_data/pitch_tiers/
        sentence OutDirIntensityTier xxx/praat_data/intensity_tiers/
        comment Manually inspect F0 for corrections?
        boolean inspect 0 
        comment F0 path finder settings (adjustable).
        real silenceThr 0.03
        real voicingThr 0.45
        real octave 0.01
        real octavejump 0.35
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
