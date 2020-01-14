# TITLE:		Praat's Periodic Power (PPP)
# INPUT:		Audio files (preferably at least 44.1kHz sample-rate and 16bit PCM).
# OUTPUT:		Pitch objects, pitch tiers and intensity tiers.
# NOTES:		This script creates the corresponding Praat objects (see "output") for 
#				files in the audio directory ("input"). The extracted parameters in 
#				pitch objects and intensity tiers are used in the R code to yield 
#				periodic energy curves. The pitch tier object is used for standard 
#				F0 information, which can be tweaked in fields of this script's form, 
#				and can be manually corrected when the "inspect" option is switched on.
# AUTHORS:		Aviad Albert and Francesco Cangemi {a.albert / fcangemi} @uni-koeln.de

####### Input form
form Input parameters
        comment Directories (with final slash):
        sentence InDirAudio /xxx/audio/
        sentence OutDirPitchObject	/xxx/praat_data/pitch_objects/3rd_pass_r_type/
        sentence OutDirPitchTier /xxx/praat_data/pitch_tiers/3rd_pass_r_type/
        sentence OutDirIntensityTier /xxx/praat_data/intensity_tiers/3rd_pass_r_type/
        comment Manually inspect F0 for corrections?
        boolean inspect 0 
        comment F0 path finder settings (adjustable):
        real silenceThr 0.03
        real voicingThr 0.45
        real octave 0.01
        real octavejump 0.35
        real voiceunvoiced 0.14
        integer pitchmax 600
        comment F0 smoothing bandwidth (Hz)
        integer smooth 10
endform
Erase all

####### Settings

Create Strings as file list: "soundFileObj",  "'InDirAudio$'*.wav"
number_of_files = Get number of strings
for i from 1 to number_of_files
	selectObject: "Strings soundFileObj"
	current_file$ = Get string: 'i'
	name_prefix$ = current_file$ - ".wav"

	Read from file: "'InDirAudio$''current_file$'"
		To Intensity: 40, 0.001, "yes"
		Down to IntensityTier
		Save as short text file: "'OutDirIntensityTier$''name_prefix$'.IntensityTier"
		Remove
		selectObject: "Intensity 'name_prefix$'"
		Remove

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
  
  select all
    minusObject: "Strings soundFileObj"
    Remove

endfor
select all
Remove
