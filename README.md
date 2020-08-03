# ProPer
### PROsodic analysis with PERiodic energy
#### A workflow for periodic energy extraction and usage (with Praat and R)  
*Aviad Albert, Francesco Cangemi & Martine Grice*  
{a.albert/fcangemi/martine.grice}\@uni-koeln.de

## Instructions for the ProPer workflow
If you have *RStudio*, it is recommended to open the R project `ProPer_Projekt.Rproj` in order to manange all the files in this workflow (otherwise use the individual .Rmd files within the folder) and proceed as follows:

### 1) ProPer pre-preparation: Acoustics-to-Praat
**Data extraction from Praat (Praat script)**

Copy the Praat script from `1) ProPer pre-preparation (Acoustics-to-Praat).praat` into a Praat script window (or double-click the file to open directly in a Praat script window). Make sure that the directory paths are correct (change 'xxx' directly in the script or in the prompted Praat form), and make sure that your audio file(s) are/is in the "audio" directory (preferably PCM with 44.1kHz sample-rate and 16-24 bit depth).

We use the pitch objects in Praat to extract the *periodic fraction* of the signal via the strength of the pitch candidates, denoting the strength of similarity in the auto-correlation from 0 to 1. To eventually get the *periodic power*, the periodic fraction is multiplied by the *total power*, which we derive from the intensity tier. To keep things consistent, the parameters that determine Praat's intensity and pitch candidates analysis are "hard-coded" to the script (i.e. their values are given in constant numbers and they don't show up in the form). The parameters that appear in the form can only change Praat's F0 path finding algorithm, which influences Praat's choice of F0 among the given candidates. These can be freely adjusted to optimize F0 detection without affecting the periodic power reading.

The Praat script is based on *mausmooth* (Cangemi & Albert 2016), prompting a grouped view of the sound and pitch objects of each item in the list, allowing the user to correct pitch candidates in the pitch object (e.g. octave jumps) before the pitch object and the smoothed pitch tier are saved. This behavior can be switched off in the form by declicking "inspect" (the pitch objects and tiers will be automatically created and saved). 

### 2) ProPer preparation: Praat-to-R
**Import Praat data into R tables (create `raw_df.csv`)**

The R codes in `2) ProPer preparation (Praat-to-R).Rmd` use the *rPraat* package to directly read Praat's objects and tiers and collect all selected parameters into a data table with all the raw data (*raw_df*).

Note that these codes allow for optional data from Praat's TextGrids that the user can create separately and place in the "praat_data/textgrids" directory. The current setting is designed to read a single interval tier ("seg") demarcating segments/syllables/words (boundaries and annotations).

### 3) ProPer visualization: Periograms
**Prepare the main data table (create `main_df.csv`)**

The codes in `3) ProPer visualization (Periograms).Rmd` result in the visualization paradigm that we call ***Periograms***, where the F0 contour is visually modulated (thickness and transparency) in accordance with corresponding periodic energy levels (see Albert et al. 2018, 2019).

The first part of `ProPer visualization (Periograms)` requires/allows interaction with a few important variables, before it creates new data based on these determinations:

+ **sampleRate**: The number of data points per second (should be 1000 in the current wrokflow).
+ **strengthresh**: Determine the effective floor for the periodic fraction. Values under this threshold do not count as periodic (akin to Praat's *voicing threshold*). This floor can be as high as 0.5 (50%) of the autocorrelation similarity strength.
+ **per_floor**: Determine the effective floor of the final periodic energy curve to eliminate low-energy fluctuations. Should be set to capture the low end between 0.001 (0.1%) and 0.05 (5%) of the range. Preferably, sets of clear voiceless portions from a given recording session can be used to inform this threshold (e.g. by finding the maximum periodic reading at these voiceless regions and setting it as the floor).
+ **rel_to**: Choose "stim", "speaker" or "data" to determine if the above-mentioned percentage-based thresholds are calculated for each stimulus relative to itself ("stim"), to  speaker-defined sets ("speaker") or, in the case of a single recording session with a single speaker, relative to the whole data set ("data"). 

Note that we create 4 flavors of smoothing for the periodic energy curve. We use low-pass filters of 20Hz, 12Hz, 8Hz and 5Hz to achieve smoothing in intervals of 50, 83, 125 and 200 ms sizes (respectively). The 20Hz/5ms smoothing is targeting segmental-size intervals, while the 5Hz/200ms smoothing is targeting syllable-size intervals, and we provide 2 more stages in between. The different rates may be adjusted to fit different data. Note also that the different smoothing spans can be useful at later stages, for automatic detection of boundaries, regardless of the periogram representation selected here.

The final interpolated F0 is smoothed with a 6Hz low-pass filter (166.7 ms intervals) given that 6Hz is closest to naturally occuring vibrato in singing voices.

Use the plots at the end of the file to inspect the data and adjust the thresholds before saving the *main_df* table.

### 4) ProPer analyses: Synchrony, PEM, etc.
**Perform computations on the data (create `comp_df.csv`)**

The codes in `4) ProPer analyses (Synchrony PEM etc).Rmd` are designed to extract quantifiable data using periodic energy (see Cangemi et al. 2019). It starts with a boundary detector to locate the syllabic boundaries. We use an automatic method, based on 1st and 2nd derivatives of the periodic energy curve to locate relevant minima. The following computations are performed within and across the resulting intervals:

+ **AUC**: The area under the periodic energy curve is computed to reflect the *Periodic Energy Mass* (**PEM**), related to prosodic *prominence*.
+ **CoM**: The center of mass of periodic energy within syllables is extracted. 
+ **CoG**: The center of gravity of F0 within syllables is extracted.
+ **Synchrony**: The distance between the two centers (CoM and CoG) is indicative of the overall F0 trend within syllables.
+ **Scaling**: We measure F0 within each syllable at the center of mass of periodic energy (CoM), and we compute *scaling* in terms of the difference in F0 from previous syllable (hence, not applicable for phrase-initial syllables).

Again, use the plot at the end of the file to inspect the data and adjust parameters before saving the *comp_df* table.

***

#### References
Albert, Aviad, Francesco Cangemi & Martine Grice. 2018. Using periodic energy to enrich acoustic representations of pitch in speech: A demonstration. In *Proceedings of the 9th International Conference on Speech Prosody*. Poznań, Poland. [link](https://www.isca-speech.org/archive/SpeechProsody_2018/abstracts/220.html)

Albert, Aviad, Francesco Cangemi & Martine Grice. 2019. Can you draw me a question? Winning presentation at the *Prosody Visualization Challenge 2*. ICPhS, Melbourne, Australia. [link](https://www.researchgate.net/publication/335096657_Can_you_draw_me_a_question?channel=doi&linkId=5d4e86644585153e5949fcb7&showFulltext=true)

Cangemi, Francesco & Aviad Albert. 2016. mausmooth: Eyeballing made easy. Poster presentation at *the 7th conference on Tone and Intonation in Europe (TIE)*. Canterbury, UK.

Cangemi, Francesco, Aviad Albert & Martine Grice. 2019. Modelling intonation: Beyond segments and tonal targets. In *Proceedings of the International Congress of Phonetic Sciences*. Melbourne, Australia. [link](https://www.researchgate.net/publication/335096495_Modelling_intonation_Beyond_segments_and_tonal_targets)