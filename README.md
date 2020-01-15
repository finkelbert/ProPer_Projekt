# Periogram-Projekt
#### A workflow for periodic energy extraction using Praat and R  
*Aviad Albert & Francesco Cangemi*  
{a.albert/fcangemi}\@uni-koeln.de

## Instructions 

### 1. Data extraction from Praat (Praat script)
Copy the Praat script from `1_Praat_script.praat` into a Praat script window (or double-click it to open directly in a Praat script window). Make sure that the directory paths are correct (change directly in the script or in the prompted Praat form), and make sure that your audio file(s) are/is in the "audio" directory (preferably PCM with 44.1kHz sample-rate and 16-24 bit depth).

We use the pitch objects in Praat to extract the *periodic fraction* of the signal via the strength of the pitch candidates, denoting the strength of similarity in the auto-correlation from 0 to 1. To eventually get the *periodic power*, the periodic fraction is multiplied by the *total power*, which we derive from the intensity tier. To keep things consistent, the parameters that determine Praat's intensity and pitch candidates analysis are "hard-coded" to the script (i.e. their values are given in constant numbers and they don't show up in the form). The parameters that appear in the form can only change Praat's F0 path finding algorithm, which influences Praat's choice of F0 among the given candidates. These can be freely adjusted to optimize F0 detection without affecting the periodic power reading.

The Praat script is based on *mausmooth* (Cangemi 2015), prompting a grouped view of the sound and pitch objects of each item in the list, allowing the user to correct pitch candidates in the pitch object (e.g. octave jumps) before the pitch object and the smoothed pitch tier are saved. This behavior can be switched off in the form by declicking "inspect" (the pitch objects and tiers will be automatically created and saved). 

### 2. Import Praat data into R tables (raw_df)
The R codes in `2_PPP_raw.Rmd` use the *rPraat* package to directly read Praat's objects and tiers and collect all selected parameters into a data table with all the raw data (*raw_df*).

Note that these codes allow for optional data from Praat's TextGrids that the user can create separately and place in the "praat_data/textgrids" directory. The current setting is designed to read a single interval tier ("seg") demarcating segments/syllables/words (boundaries and annotations).

### 3. Prepare the main data table (main_df)
The codes in `3_PPP_main.Rmd` result in the visualization paradigm that we call ***Periograms***, where the F0 contour is visually modulated (thickness and transparency) in accordance with corresponding periodic energy levels (see Albert et al. 2018, 2019).

The first part of `3_PPP_main` requires/allows interaction with a few important variables, before it creates new data based on these determinations:

+ To achieve a functionality that resembles Praat's voicing threshold in the pitch analysis settings, effectively eliminating noise from the lower values of the HNR/periodic fraction, we set a "strengthresh" value, which can be as high as 50% of the strength scale (0.5).
+ The periodic power is needs to be log-transformed. We set a "silence threshold" in the log function by determining the "per_floor" value, which will determine the zero value of the log scale (this threshold is usually under 5% of the exponential scale).
+ By entering "stim" or "data" (or "speaker" if added) in the "stim_data" variable, we can determine if the above-mentioned thresholds are calculated relative to each stimulus/file ("stim"), each speaker ("speaker") or, in the case of a single recording session with a single speaker, relative to the whole data set. 
+ The log periodic power is eventually smoothed by a local polynomial regression fitting (loess). The amount of smoothing is determined in the "per_smooth_span" variable.
+ For *periograms*, we create an interpolated version of the F0 curve. We then fit a smooth curve to the interpolated F0. The amount of this smoothing can be changed using the "f0_smooth_span" variable.

Note that at the end of this process we have two final periodic enrgy curves: "smog_pp_gnrl(_rel)" and "smog_pp_f0(_rel)" (versions with '_rel' denote a relative scale from 0 to 1). The former (smog_pp_gnrl), which we currently consider as the default, or "general", is unaffected by Praat's path finding algorithm and its choice of F0, and it can be fine-tuned here via the "strengthresh" variable similarly to Praat's voicing threshold. The latter (smog_pp_f0) reflects the strength values of the F0 pitch candidates (thus, "F0-related"), which depend on the settings of the path finding algorithm in Praat (as well as on manual corrections). It has the ability to prefer harmonically resolved candidates (thus eliminating noise from strong harmonically unrelated candidates, if they happen to appear within the F0 range), and it may also favor a low frequency candidate with low strength value over a stronger and higher harmonically related partial. In any case, they are almost identical when they are both with low threshold settings, so this ends up being mostly a choice between slightly different fine-tunes.

### 4. Perform computations on the data (comp_df)
The codes in `4_PPP_comp.Rmd` are designed to extract quantifiable data using periodic energy (see Cangemi et al. 2019). It starts with a boundary detector to locate the syllabic boundaries. We use an automatic method, based on 1st and 2nd derivatives of the periodic energy curve to locate relevant minima. The following computations are performed within and across the resulting intervals:

+ **AUC**: The area under the periodic energy curve is computed to reflect the periodic *mass*, related to prosodic *prominence*.
+ **CoM**: The center of mass of periodic energy within syllables is extracted. 
+ **CoG**: The center of gravity of F0 within syllables is extracted (see Barnes et al. 2012).
+ **Synchrony**: The distance between the two centers (CoM and CoG) is indicative of the overall F0 trend within syllables.
+ **Scaling**: We measure F0 within each syllable at the center of mass of periodic energy (CoM), and we compute *scaling* in terms of the difference in F0 from previous syllable (hence, not applicable for phrase-initial syllables).

***

#### References
Albert, Aviad, Francesco Cangemi, and Martine Grice. 2018. Using periodic energy to enrich acoustic representations of pitch in speech: A demonstration. In *Proceedings of the 9th International Conference on Speech Prosody*. [link](https://www.isca-speech.org/archive/SpeechProsody_2018/abstracts/220.html)

Albert, Aviad, Francesco Cangemi, and Martine Grice. 2019. Can you draw me a question? Winning presentation at the *Prosody Visualization Challenge 2*, ICPhS, Melbourne, Australia. [link](https://www.researchgate.net/publication/335096657_Can_you_draw_me_a_question?channel=doi&linkId=5d4e86644585153e5949fcb7&showFulltext=true)

Barnes, Jonathan, Nanette Veilleux, Alejna Brugos, and Stefanie Shattuck-Hufnagel. 2012. Tonal center of gravity: A global approach to tonal implementation in a level-based intonational phonology. *Laboratory Phonology* 3 (2): 337-383.

Cangemi, Francesco, Aviad Albert, and Martine Grice. 2019. Modelling intonation: Beyond segments and tonal targets. In *Proceedings of the International Congress of Phonetic Sciences*, Melbourne, Australia. [link](https://www.researchgate.net/publication/335096495_Modelling_intonation_Beyond_segments_and_tonal_targets)