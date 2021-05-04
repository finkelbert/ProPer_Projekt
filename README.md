# ProPer
### PROsodic analysis with PERiodic energy
#### A workflow for periodic energy extraction and usage (with Praat and R)  
*Aviad Albert, Francesco Cangemi, T. Mark Ellison & Martine Grice*  
*IƒL - Phonetik, University of Cologne, Germany*  
{a.albert/fcangemi/t.m.ellison/martine.grice}\@uni-koeln.de

---

## Instructions for the ProPer workflow
(last update: 5 April 2021)

### 0. Before you begin
##### Compatibility issues

**File names**  

* File names should not include special characters (e.g. IPA or diacritics), as well as spaces or dots. It is recommended to use an uderscore to separate filename elements (e.g. *interrogative_speaker1_sentence1.wav*).

**Audio**  

* Audio files should be preferably mono, non-compressed (e.g. PCM such as *.wav* or *.aiff*) with 16--24 bit depth and up to 44.1k/48kHz sample-rate. This full-range sample-rate resolution is recommended but not essential. The bulk of periodic energy in speech is below 1kHz, so, in essence, sample-rates above 2kHz should suffice for adequate perception of continuous sound from discrete samples (the *Nyquist rate*). 
  
* Regardless of whichever sample-rate is being used, make sure that the sample-rate is identical in all your audio files (and remember that sample-rate conversion is a one-way street: upsampling cannot improve sound quality).

* It is recommended to normalize the loudness of all audio files to the same target BEFORE the Praat analysis takes place. This could be a simple average target (e.g. *RMS*) or a more advanced Loudness Unit target (*LU*). In both cases the recommeded value is -23 given dBFS for an RMS-based target or LUFS for the LU target (FS = full scale, where '0' is the maximal posiible value). Freely available loudness normalization can be done with [Audacity](https://www.audacityteam.org/) where it is also possible to batch process many files via *macros*. Note that the LUFS normaliztion in Audacity is found under *Effect -> Loudness Normalization -> perceived loudness*. It should be set to -23LUFS, and you should deselect "Treat mono as dual-mono" since this will actually result in a -26LUFS. That said, whatever value you choose, the important thing is to keep a consistent target value for the entire data set.

* Audio files should have at least 200 ms without a signal (i.e. without acoustic material that needs to be analyzed) on both ends, initial and final, due to limitations in Praat's analysis at file edges. If this distance is not available on file, it is possible to insert additional silence to the audio file (see, e.g., [here](http://www.ddaidone.com/uploads/1/0/5/2/105292729/insert_silence_at_start_of_all_files_in_folder.txt) and [here](http://www.ddaidone.com/uploads/1/0/5/2/105292729/insert_silence_at_end_of_all_files_in_folder.txt)). See also next point about TextGrids in case you added silent portions to the audio AFTER the TextGrids were created.

**TextGrids**  

* If you need to extend existing TextGrids by certain amounts of milliseconds on both sides (assuming that the corresponding audio file had to change to satisfy Praat's limitations, see previous point), the following Praat script commands can help:  
`Extend time: 0.2, "End"`  
`Extend time: 0.2, "Start"`  
`Shift times by: 0.2`

* For most dsirable interface with the R codes, it is highly recommended to manually segment syllable-sized intervals in the TextGrid. The automatic detection of major periodic energy fluctuations in ProPer can make use of manual syllabic segmentation for optimal results.
  
* Avoid special characters (e.g. IPA or diacritics) in the TextGrid tiers. 
  
* Leave empty intervals without text if they are not marking portions of speech to be analyzed (e.g. first and last TextGrid intervals should be empty).

**Managing R code**  

* If you have [*RStudio*](https://www.rstudio.com/), it is recommended to open the R Project file, `ProPer_Projekt.Rproj`, to use the different R Markdown files and manange the entire working directory from one central interface. Otherwise, simply use the individual R Markdown files (ending with *.Rmd*) directly.

---

### 1. ProPer pre-preparation: Acoustics-to-Praat
##### Data extraction from Praat (Praat script)

Copy the Praat script from `1) ProPer pre-preparation (Acoustics-to-Praat).praat` into a Praat script window (or double-click the file to open directly in a Praat script window). Make sure that the directory paths are correct (change 'xxx' directly in the script or in the prompted Praat form), and make sure that your audio file(s) are/is in the "audio" directory (see notes on audio compatability issues above).

We use the *Pitch object* in Praat to extract the *periodic fraction* of the signal from the *strength* values that are associated with each pitch candidate. The strength scale in the pitch object (running from 0 to 1) reflects the extenet to which the acoustic signal is similar to itself across selected time points in the auto-correlation function. This similarity characterizes periodic signals, but it is not informative about the power of the signal. We need to multiply the periodic fraction by the *total power*, which we derive from the intensity tier to calculate the *periodic power*.

The Praat script is based on *mausmooth* (Cangemi & Albert 2016), prompting a grouped view of the audio and pitch objects of each item in the list, allowing the user to correct pitch candidates in the pitch object (e.g. fix octave jumps) before the pitch object and the smoothed pitch tier are saved. This behavior can be switched off in the form by deselecting "inspect" (the pitch objects and tiers will be automatically created and saved). 

To keep things consistent, the parameters that determine Praat's intensity and pitch candidates analysis are "hard-coded" into the script, i.e. their values are given in constant numbers and they don't show up in the adjustable form. The parameters that appear in the form can only change Praat's F0 path finding algorithm, which influences Praat's choice of F0 among the given candidates. These can be freely adjusted to optimize F0 detection without affecting the calculation of periodic power.

### 2) ProPer preparation: Praat-to-R
##### Import Praat data into R tables (create `raw_df.csv`)

The R codes in `2) ProPer preparation (Praat-to-R).Rmd` use the [*rPraat* package](https://fu.ff.cuni.cz/praat/rDemo.html) to directly read Praat's object files  and collect all selected parameters into an R data frame with all the relevant raw data from Praat (*raw_df*).

Note that these codes allow for optional data from Praat's TextGrids that the user is encouraged to create separately and place in the "praat_data/textgrids" directory. The current settings are designed to read two interval tiers, "Syllable" and "Word", that demarcate units of these sizes with boundaries and text annotations.

### 3) ProPer visualization: Periograms
##### Prepare the main data table (create `main_df.csv`)

The codes in `3) ProPer visualization (Periograms).Rmd` are designed to calculate and shape the *periodic energy* curve from the *periodic power* vector after the application of log-transform and smoothing functions. This is enough to achieve the first goal: rich 3-dimensional visualization of pitch contours, a.k.a. ***Periograms***. Periograms show the F0 trajectory whereby time is on the x-axis and frequency is on the y-axis---as in most common practices---while also reflecting the stregnth of the perceived pitch contour continuously in terms of the thickness and darkness of the F0 curve (see Albert et al. 2018, 2019).

The first part of `ProPer visualization (Periograms)` presents adjustable presets that summarize the important variables for the periodic energy adjustment phase:

+ **perFloor**: Determine the effective floor (zero) of the final periodic energy curve to eliminate low-energy fluctuations. Should be set to capture the low end between 0.001 (0.1%) and 0.05 (5%) of the range of the *periodic power* vector. Note that *perFloor* values have a strong impact on the resulting curve and should be carefully adjusted for your data. Ideally, this value should be the same for similar recording conditions. If no single *perFloor* value is good enough (e.g. when the recording conditions of the data are diverse) it is possible to set *perFloorFix* values for individual flies in the set.

+ **strengThresh**: Determine the effective floor for the periodic fraction. Values under this threshold do not count as periodic at all (akin to Praat's *voicing threshold*). This floor can be as high as 0.5 (50%) of the autocorrelation similarity strength. However, we recommend keeping it at 0.25 (25%) and only adjust this parameter if you know that it is needed.

+ **relTo**: Choose "stim", "speaker" or "data" to determine if the above-mentioned percentage-based thresholds are calculated for each stimulus relative to itself ("stim"), to speaker-defined sets of the same speaker ("speaker") or, in the case of a single recording session with a single speaker, relative to the whole data set ("data"). 

Note that we create 4 flavors of smoothing for the periodic energy curve. We use low-pass filters of 20Hz, 12Hz, 8Hz and 5Hz to achieve smoothing in intervals of 50, 83, 125 and 200 ms sizes (respectively). The 20Hz smoothing is targeting segmental-size intervals (as short as 50 ms), while the 5Hz smoothing is targeting syllable-size intervals (at 200 ms). We provide 2 more smoothing stages in between those two ends of the spectrum with 8Hz and 12Hz low-pass filters.[^smoothing] 

[^smoothing]: The code in this script also interpolates and smooths the F0 contour from Praat's pitch tier. We smooth the final F0 contours with a 6Hz low-pass filter (166.7 ms intervals), to retain the affinity to syllable-size intervals and given that 6Hz is closest to naturally occuring vibrato in singing voices (Cook 2001).

Use the plots in the code chunks to inspect the data and adjust the thresholds before saving the *main_df* data frame as a .csv table.

### 4) ProPer analyses: Synchrony etc.
##### Detect intervals and perform computations on the data (create `comp_df.csv`)

The codes in `4) ProPer analyses (Synchrony etc.).Rmd` are designed to extract ProPer quantifiable data on F0 shape (*Synchrony* and *∆F0*/*DeltaF0*), prosodic prominence (*Mass*) and local *Speech-rate* (see Cangemi et al. 2019 on Synchrony). It starts with a boundary detector to locate the intervals of interest. Then, a suite of functions are mapped to the syllabic intervals to calculate the different parameters. Finally, dense plots with superimposed data are being produced for presentation and verification before saving the *comp_df* data frame as a .csv table. 

The automatic boundary detector is designed to locate local minima in the periodic energy curve while also taking into account information from the optional "Syllable" tier in a corresponding TextGrid. Manual segmentation can guide the automatic detector and help in targeting specific syllables of interest and is therefore highly recommended for ProPer analyses.

**The following is a brief description of the calculations we perform**:

+ **Mass**: The area under the periodic energy curve is computed to reflect the *Mass*, as the integral of duration and power, which is related to prosodic *prominence*.
+ **CoM**: The Center of Mass of periodic energy within intervals. 
+ **CoG**: The Center of Gravity of F0 within intervals (related to the Tonal Center of Gravity; Barnes et al. 2012).
+ **Synchrony**: The distance between the two centers (CoM and CoG) is indicative of the overall F0 trend within syllables (rising/falling/level).
+ **∆F0/DeltaF0**: We measure F0 within each interval at the center of mass of periodic energy (CoM), and we compute *∆F0*/*DeltaF0* in terms of the difference in F0 from previous interval to reflect the F0 shape across syllables. For the first interval we compute the difference from the speaker's median F0.
+ **Speech-rate**: We calculate the temporal distance between consecutive CoMs to yield a local speech-rate curve. For the first interval we compute the relative duration compared to the maximal interval duration in the same speech item.

***

#### References
Albert, Aviad, Francesco Cangemi & Martine Grice. 2018. Using periodic energy to enrich acoustic representations of pitch in speech: A demonstration. In *Proceedings of the 9th International Conference on Speech Prosody*. Poznań, Poland. [link](https://www.isca-speech.org/archive/SpeechProsody_2018/abstracts/220.html)

Albert, Aviad, Francesco Cangemi & Martine Grice. 2019. Can you draw me a question? Winning presentation at the *Prosody Visualization Challenge 2*. ICPhS, Melbourne, Australia. [link](https://www.researchgate.net/publication/335096657_Can_you_draw_me_a_question?channel=doi&linkId=5d4e86644585153e5949fcb7&showFulltext=true)

Barnes, Jonathan, Nanette Veilleux, Alejna Brugos, and Stefanie Shattuck-Hufnagel. 2012. Tonal center of gravity: A global approach to tonal implementation in a level-based intonational phonology. *Laboratory Phonology* 3 (2): 337-383.

Cangemi, Francesco & Aviad Albert. 2016. mausmooth: Eyeballing made easy. Poster presentation at *the 7th conference on Tone and Intonation in Europe (TIE)*. Canterbury, UK.

Cangemi, Francesco, Aviad Albert & Martine Grice. 2019. Modelling intonation: Beyond segments and tonal targets. In *Proceedings of the International Congress of Phonetic Sciences*. Melbourne, Australia. [link](https://www.researchgate.net/publication/335096495_Modelling_intonation_Beyond_segments_and_tonal_targets)

Cook, Perry R. 2001. Pitch, periodicity, and noise in the voice. In *Music, Cognition, and Computerized Sound: An Introduction to Psychoacoustics*. Ed. Perry R Cook. Cambridge, Mass.: MIT Press.