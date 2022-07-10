

![](https://finkelbert.files.wordpress.com/2021/06/proper-logo4a-small-tight.png)

Aviad Albert, Francesco Cangemi, T. Mark Ellison & Martine Grice  
*IƒL - Phonetik, University of Cologne*  

---

## Instructions for the ProPer workflow
(last update: 9 July 2022)

### 0. Before you begin

This workflow requires [Praat](https://www.fon.hum.uva.nl/praat/), [R](https://www.r-project.org/) and 
[RStudio](https://www.rstudio.com/).  


**File names**  

* File names should not include special characters (e.g. IPA or diacritics), white spaces or dots. It is recommended to use an underscore to separate file name elements (e.g. *interrogative_speaker1_sentence1.wav*).

**Audio**  

* Audio files should be preferably mono, non-compressed (PCM files such as `.wav` or `.aiff`) with 16--24 bit depth and up to 44.1/48 kHz sample rate. This full-range sample rate resolution is recommended but not essential. To capture the bulk of periodic energy in speech signals we crucially need to cover frequencies up to 8 kHz. Given the *Nyquist rate*, sample rates that are twice as fast, from 16 kHz and above, should suffice for adequate analysis of continuous F0 and periodic energy.

* Regardless of whichever sample rate is being used, make sure that the sample rate is identical in all your audio files (and remember that sample rate conversion is a one-way street: upsampling cannot improve sound quality).

* It is recommended to normalize the loudness of all audio files to the same target BEFORE the Praat analysis takes place. This could be a simple average target (e.g. *RMS*) or a more advanced Loudness Unit target, *LU*. In both cases the recommended value is -23 given dBFS for an RMS-based target or LUFS for the LU target (FS = full scale, where '0' is the maximal possible value). Freely available loudness normalization can be done with [Audacity](https://www.audacityteam.org/) where it is also possible to batch process many files via *macros*. Note that the LUFS normalization in Audacity is found under *Effect -> Loudness Normalization -> perceived loudness*. It should be set to -23 LUFS, and you should deselect "Treat mono as dual-mono" since this will actually result in a -26 LUFS if selected. That said, whatever value you choose, the important thing is to keep a consistent target value for the entire data set (without getting any audio clipping at zero).

* Audio files should ideally have 200 ms without a signal (i.e. without acoustic material that needs to be analyzed) on both ends, initial and final, due to limitations in Praat's analysis at file edges. If this distance is not available on file, it is possible to insert additional silence to the audio file (see, e.g., [here](http://www.ddaidone.com/uploads/1/0/5/2/105292729/insert_silence_at_start_of_all_files_in_folder.txt) and [here](http://www.ddaidone.com/uploads/1/0/5/2/105292729/insert_silence_at_end_of_all_files_in_folder.txt)). See also next point about TextGrids in case you added silent portions to the audio AFTER the TextGrids were created.

**TextGrids**  

* If you need to extend existing TextGrids by certain amounts of milliseconds on both sides (assuming that the corresponding audio file had to change to satisfy Praat's limitations, see previous point), the following Praat script commands can help (here, adding 200 ms on both ends):  
`Extend time: 0.2, "End"`  
`Extend time: 0.2, "Start"`  
`Shift times by: 0.2`

* For the most effective interface with the ProPer workflow, it is highly recommended to provide syllable-sized intervals using Praat's TextGrids. The boundary detection algorithm in ProPer can incorporate Praat's segmentation information with the signal-based boundaries that are automatically found based on the periodic energy curve.
  
* It is recommended to avoid special characters (e.g. IPA or diacritics) in the TextGrid tiers. 
  
* Leave empty intervals without text if they are not marking portions of speech to be analyzed (e.g. first and last TextGrid spaces should be empty).

**Managing and using the workflow files**  

* We recommend using [*RStudio*](https://www.rstudio.com/)'s R Project file, `ProPer_Projekt.Rproj`, to manage your workflow in an autonomous manner. Project files are also useful for adding version control (e.g. *git*) to your workflow. If you don't use the workflow under an R Project, you can simply use the individual R Markdown files (`*.Rmd`) directly.

* ProPer scripts are incrementally ordered such that each (numbered) script builds on the previous one. The first (Praat) script creates Praat objects that the second (R) script collects into a table. The second, as well as all the following R scripts, end by writing a summary table in standard `.csv` format. The third to last script therfore always begin by reading the `.csv` file that was created in the previous stage.

---

### 1. ProPer pre-preparation: Acoustics-to-Praat
##### Data extraction from Praat (Praat script)

Copy the Praat script from `1) ProPer pre-preparation (Acoustics-to-Praat).praat` into a Praat script window (or double-click the file to open directly in a Praat script window). You should keep the files and folders structure of the original workflow (otherwise, specify the paths to relevant folders directly in the Praat script or in the prompted script's form). Also, make sure that your audio files are in the 'audio/' directory (likewise, if TextGrids are provided, make sure they are in the 'praat_data/textgrids/' directory).

We use the *Pitch object* in Praat to extract the *periodic fraction* of the signal from the *strength* values that are associated with each "pitch candidate" in Praat. The strength scale in the pitch object (from 0 to 1) reflects the extent to which the acoustic signal is similar to itself across selected time points in the autocorrelation function. This similarity characterizes periodic signals, but it is not informative w.r.t. the amplitude of the signal. We need to multiply the periodic fraction by the *total power*, which we derive from the intensity tier to calculate the *periodic power*.

The Praat script is based on *mausmooth* (Cangemi & Albert 2016), prompting a grouped view of the audio and pitch objects of each item in the list, allowing the user to correct pitch candidates in the pitch object (e.g. fix octave jumps) before the pitch object and the smoothed pitch tier are saved. This behavior can be switched off in the form by deselecting "inspect" (the pitch objects and tiers will be automatically created and saved). 

To keep things consistent, the parameters that determine Praat's intensity and pitch candidates analysis are "hard-coded" into the script, i.e. their values are given in constant numbers and they don't show up in the adjustable form. The parameters that appear in the form can only change Praat's F0 path finding algorithm, which influences Praat's choice of F0 among the given candidates. These can be freely adjusted to optimize F0 detection without affecting the calculation of periodic power.

### 2) ProPer preparation: Praat-to-R
##### Import Praat data into R tables (create `raw_df.csv`)

The R codes in `2) ProPer preparation (Praat-to-R).Rmd` use the [*rPraat* package](https://fu.ff.cuni.cz/praat/rDemo.html) to directly read Praat's object files and collect all selected parameters into an R data frame with all the relevant raw data from Praat (*raw_df*).

Note how 'filename' is extracted in each of the data frames (e.g. *intensity_df*, *f0_smooth_df* etc.), and see how 'speaker' is further extracted from the file names in *fullTime_df*. You should be able to design the code to extract any other file name variable according to your needs, using this example.

Note that these codes allow for optional data from Praat's TextGrids that the user is encouraged to create separately and place in the "praat_data/textgrids" subdirectory. The current settings are designed to read two interval tiers, "Syllable" and "Word", that demarcate units of these sizes with boundaries and text annotations.

### 3) ProPer visualization: Periograms
##### Prepare the main data table (create `main_df.csv`)

The codes in `3) ProPer visualization (Periograms).Rmd` are designed to calculate and shape the *periodic energy* curve from the *periodic power* vector after the application of log-transform and smoothing functions. This is enough to achieve the first goal: rich 3-dimensional visualization of pitch contours, a.k.a. ***Periograms***. Periograms show the F0 trajectory whereby time is on the x-axis and frequency is on the y-axis---as in most common practices---while also reflecting the strength of the perceived pitch contour continuously in terms of the thickness and darkness of the F0 curve (see Albert et al. 2018, 2019).

The first part of `ProPer visualization (Periograms)` presents adjustable presets that summarize the important variables for the periodic energy adjustment phase:

+ **perFloor**: Determine the effective floor (zero) of the final periodic energy curve to eliminate low-amplitude fluctuations. *perFloor* should be usually set to capture the low end between 0.001 (0.1%) and 0.05 (5%) of the range of the *periodic power* vector. Note that *perFloor* values have a strong impact on the resulting curve and should be carefully adjusted for your data. Ideally, this value should be the same for similar recording conditions. If no single *perFloor* value is good enough (e.g. when the recording conditions of the data are diverse) it is possible to set *perFloorFix* values for individual flies in the set.

+ **strengThresh**: Determine the effective floor for the periodic fraction. Values under this threshold do not count as periodic at all (akin to Praat's *voicing threshold*). This floor can be as high as 0.5 (50%) of the autocorrelation similarity strength. However, we recommend keeping it at 0.25 (25%) and only adjust this parameter if you know that it is needed.

+ **relTo**: Choose "token", "speaker" or "data" to determine if the above-mentioned percentage-based thresholds are calculated for each token relative to itself ("token"), to speaker-defined sets of the same speaker ("speaker") or, in the case of a single recording session with a single speaker, relative to the whole data set ("data"). 

Note that we create 4 flavors of smoothing for the periodic energy curve. We use low-pass filters of 20, 12, 8 and 5 Hz. The 20 Hz filtering (the least smooth variant) targets segmental-size intervals (as short as 50 ms), while the 5 Hz filtering (the smoothest variant) is targeting syllable-size intervals (at 200 ms). We provide 2 more smoothing stages in between those two ends of a spectrum, with 8 and 12 Hz low-pass filters (corresponding to intervals of 125 and 83 ms sizes respectively).[^smoothing] 

[^smoothing]: The code in this script also interpolates and smooths the F0 contour from Praat's pitch tier. We smooth the final F0 contours with a 6 Hz low-pass filter (166.7 ms intervals), to retain the affinity to syllable-size intervals and given that 6 Hz is closest to naturally occurring vibrato in singing voices (Cook 2001).

The ggplot sections run in a loop, creating plots for each individual audio file. The plots are saved in pdf format under 'plots/', and they are in print quality. Feel free to adjust the look (colors, fonts, etc.). These plots are also crucial to inspecting the data and adjusting the parameters (see above) to achieve the optimal periodic energy curves before saving the *main_df* data frame as a `.csv` file.

### 4) ProPer analyses: Synchrony etc.
##### Detect intervals and perform computations on the data (create `comp_df.csv`)

The codes in `4) ProPer analyses (Synchrony etc.).Rmd` are designed to extract ProPer quantifiable data on F0 shape (*Synchrony* and *∆F0*), prosodic prominence (*Mass*) and local *Speech rate* (see Cangemi et al. 2019 on Synchrony). We start with a boundary detector to locate the intervals of interest. Then, a suite of functions are mapped to the syllabic intervals to calculate the different metrics. Finally, dense plots with superimposed data are being produced for presentation and verification before saving the *comp_df* data frame as a `.csv` file. 

The automatic boundary detector is designed to locate local minima in the periodic energy curve while also taking into account information from the optional *Syllable* tier in a corresponding TextGrid. Manual segmentation can guide the automatic detector and help in targeting specific syllables of interest and is therefore highly recommended for ProPer analyses.

The first part of `ProPer analyses (Synchrony etc.)` presents adjustable presets that summarize the important variables for the boundary detection algorithm:

+ **useManual**: Determine whether to consider manual segmentations in the automatic boundary detection algorithm, provided they exist (choose the default, [1], to yield *useManual = TRUE*). To prevent the algorithm from considering manual segmetations, regardless of whether they appear in the data, choose [2] to yield *useManual = FALSE*. 

The following two variables depend on the previous setting: if *useManual = TRUE* you should adjust further using *autoMan* only, and if *useManual = FALSE* you should only adjust further using *averageSyll*.

+ **autoMan**: Determine the amount of permitted distance between automatically located boundaries (*auto_bounds*) and the boundaries from Praat's TextGrid files (*syll_bounds*). The default, *40*, means that: (i) when attempting to detect boundaries, only points that are not more than 40 ms before OR after a TextGrid boundary are permitted; (ii) if after the automatic procedure there are TextGrid boundaries that have no corresponding automatically detected boundary within 40 ms before AND after them, a boundary will be added there. Lower values are therefore more restrictive. You can change *autoMan* to 0 if you wish to force the TextGrid segmentation on all the detected boundaries. 

+ **averageSyll**: Determine the expected boundary number by average syllable size when the algorithm cannot consider manual segmentations (i.e. when *useManual* = FALSE). Choose an average syllable size (in ms). A good starting point should be around 175 ms.

+ (Note: if you didn't provide TextGrid data, i.e. *useManual* = FALSE, but you know the exact number of (canonical/expected) syllables in the analyzed files, you can plug that number +1 directly as the argument of the **expSyllNum** variable.)

**The following is a brief description of the calculations we perform**:

+ **Mass**: The area under the periodic energy curve is computed to reflect the *Mass*, as the integral of duration and power, which is related to prosodic *prominence*.
+ **CoM**: The Center of Mass of periodic energy within intervals. 
+ **CoG**: The Center of Gravity of F0 within intervals (related to the Tonal Center of Gravity; Barnes et al. 2012).
+ **Synchrony**: The distance between the two centers (CoM and CoG) is indicative of the overall F0 trend within syllables (rising/falling/level).
+ **∆F0**: We measure F0 within each interval at the center of mass of periodic energy (CoM), and we compute *∆F0* in terms of the difference in F0 from previous interval to reflect the F0 shape across syllables. For the first interval we compute the difference from the speaker's median F0.
+ **Speech rate**: We calculate the temporal distance between consecutive CoMs to yield a local Speech rate curve. For the first interval we compute the relative duration compared to the maximal interval duration in the same speech item.

### 5) ProPer scores: aggregated data
##### Allocate ProPer values to manually segmented intervals, for data aggregation and stats (create `scores_df.csv`)

The 5th script suggests a method to allocate the ProPer values to selected syllables, effectively reducing the table to a single row per syllable. This is useful in order to aggregate the various ProPer metrics to be presented via descriptive statistics and analyzed with inferential statistics.

ProPer metrics are measured within a periodic energy mass that has a center (CoM). We allocate these ProPer values to the TextGrid-based syllabic intervals that include their center (i.e. The Textrid interval within which CoM is found). In the cases when there are multiple CoMs in a single interval, the values of the strongest mass are chosen.

***

#### References
Albert, Aviad, Francesco Cangemi & Martine Grice. 2018. Using periodic energy to enrich acoustic representations of pitch in speech: A demonstration. In *Proceedings of the 9th International Conference on Speech Prosody*. Poznań, Poland. [link](https://www.isca-speech.org/archive/SpeechProsody_2018/abstracts/220.html)

Albert, Aviad, Francesco Cangemi & Martine Grice. 2019. Can you draw me a question? Winning presentation at the *Prosody Visualization Challenge 2*. ICPhS, Melbourne, Australia. [link](https://www.researchgate.net/publication/335096657_Can_you_draw_me_a_question?channel=doi&linkId=5d4e86644585153e5949fcb7&showFulltext=true)

Barnes, Jonathan, Nanette Veilleux, Alejna Brugos, and Stefanie Shattuck-Hufnagel. 2012. Tonal center of gravity: A global approach to tonal implementation in a level-based intonational phonology. *Laboratory Phonology* 3 (2): 337-383.

Cangemi, Francesco & Aviad Albert. 2016. mausmooth: Eyeballing made easy. Poster presentation at *the 7th conference on Tone and Intonation in Europe (TIE)*. Canterbury, UK.

Cangemi, Francesco, Aviad Albert & Martine Grice. 2019. Modelling intonation: Beyond segments and tonal targets. In *Proceedings of the International Congress of Phonetic Sciences*. Melbourne, Australia. [link](https://www.researchgate.net/publication/335096495_Modelling_intonation_Beyond_segments_and_tonal_targets)

Cook, Perry R. 2001. Pitch, periodicity, and noise in the voice. In *Music, Cognition, and Computerized Sound: An Introduction to Psychoacoustics*. Ed. Perry R Cook. Cambridge, Mass.: MIT Press.