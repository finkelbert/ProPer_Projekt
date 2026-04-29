library(rPraat)
library(data.table)

### ------------------------------------------------------------------
### HELPER FUNCTIONS
### ------------------------------------------------------------------

.remove_extension <- function(path) {
    sub("\\.[a-zA-Z0-9]*$", "", path)
}

.normalize_filename <- function(f) {
    .remove_extension(basename(f))
}

.evens <- function(x) subset(x, x %% 2 == 0)

.odds <- function(x) subset(x, x %% 2 != 0)

.list.files.wrapper <- function(path, pattern) {
    file.list <- list.files(
        path = file.path(path),
        pattern = pattern,
        full.names = TRUE
    )
    if (length(file.list) == 0) {
        warning(sprintf("No files with the extension %s were found", substr(pattern, 4, nchar(pattern))))
        return(NULL)
    }
    file.list
}

.get_files <- function(textgrids) {
    
    praat_dsp <- "praat_dsp"
    int_folder <- "praat_dsp/intensity"
    pitch_folder <- "praat_dsp/pitch"
    pitchtier_folder <- "praat_dsp/pitchtier"

    ## Check if folders exist
    if (!dir.exists(praat_dsp)) {
        stop(sprintf("The folder '%s' was not found.", praat_dsp))
    }
    if (!dir.exists(int_folder)) {
        stop(sprintf("The folder '%s' was not found.", int_folder))
    }
    if (!dir.exists(pitch_folder)) {
        stop(sprintf("The folder '%s' was not found.", pitch_folder))
    }
    if (!dir.exists(pitchtier_folder)) {
        stop(sprintf("The folder '%s' was not found.", pitchtier_folder))
    }
    if (!dir.exists(textgrids)) {
        stop(sprintf("The folder '%s' was not found.", textgrids))
    }

    ## Define extensions and target folders
    search_paths <- list(
        tg          = list(path = textgrids, pattern = ".*\\.TextGrid$"),
        int         = list(path = int_folder, pattern = ".*\\.IntensityTier$"),
        pitch       = list(path = pitch_folder, pattern = ".*\\.Pitch$"),
        pitchtier   = list(path = pitchtier_folder, pattern = ".*\\.PitchTier$")
    )

    ## Collect files
    files <- lapply(search_paths, function(spec) {
        .list.files.wrapper(spec$path, spec$pattern)
    })

    return(files)
}

### ------------------------------------------------------------------
### GET ACOUSTIC SIGNALS
### ------------------------------------------------------------------

.read_praat_object <- function(x, class, var.name) {
    ## TODO: Support for long format files
    
    lines <- readLines(x)

    ## Validate object class
    correct_class <- grepl(paste0(".*\"", class, "\""), lines[2])

    if (!correct_class) {
        stop(sprintf("A %s file is expected.", class))
    }

    ## remove header and convert to numeric
    data <- as.numeric(lines[7:length(lines)])

    ## get time points (odd indexes)
    timestamps <- data[.odds(seq_len(length(data)))]
    timestamps <- trunc(timestamps * 1000)
    
    ## get values (even indexes)
    values <- data[.evens(seq_len(length(data)))]

    end_time <- round(as.numeric(lines[5]) * 1000)
    time <- seq_len(end_time)
    idx <- timestamps

    values_no_gaps <- rep(NA_real_, length(time))
    values_no_gaps[idx] <- values

    base <- list()
    base[["file"]] <- .normalize_filename(x)
    base[["time"]] <- time
    base[[var.name]] <- values_no_gaps
    
    base
}

.get_f0 <- function(files, digits = 3) {
    dfs <- lapply(files, function (x) {
        .read_praat_object(
            x = x,
            class = "PitchTier",
            var.name = "f0_Hz"
        )   
    })
    data.table::rbindlist(dfs, use.names = TRUE, fill = FALSE)
}

.get_intensity <- function(files, digits = 3) {
    dfs <- lapply(files, function (x) {
        .read_praat_object(
            x = x,
            class = "IntensityTier",
            var.name = "intensity_dB"
        )
    })
    data.table::rbindlist(dfs, use.names = TRUE, fill = FALSE)
}

.get_periodicity <- function(files, digits = 3, fill.begin = FALSE) {
    dfs <- lapply(files, function(file) {
        
        object <- rPraat::pitch.read(file)
        array <- rPraat::pitch.toArray(object)
        
        ## Remove strength values when F0 > 1000 Hz
        array$strengthArray[array$frequencyArray > 1000] <- NA

        ## Take the highest strength value for each frame
        strengths <- matrixStats::colMaxs(array$strengthArray, na.rm = TRUE)
        strengths[!is.finite(strengths)] <- 0

        data.frame(
            file = .normalize_filename(file),
            time = trunc(array$t * 1000),
            periodicity_index = round(strengths, digits)
        )
    })
    data.table::rbindlist(dfs, use.names = TRUE, fill = FALSE)
}

### ------------------------------------------------------------------
### TEXTGRIDS
### ------------------------------------------------------------------

## TODO: TGs with different number of tiers
## TODO: TGs with tiers without names
## TODO: TGs with duplicate names
## TODO: TGs with special chars in names

.get_textgrids <- function(files) {
    tgs <- lapply(files, .get_textgrid)
    do.call(Map, c(f = function(...) rbindlist(list(...), fill = TRUE), tgs))
}

.get_textgrid <- function(file) {
    tg <- rPraat::tg.read(file)
    filename <- .normalize_filename(file)
    mapply(function(x, y) {
        .get_tier(x, y, filename = filename)        
    }, tg, names(tg), SIMPLIFY = FALSE)
}

.get_tier <- function(tier_data, tier_name, filename) {
    if (tier_data$type == "point") {
        .get_point_tier(tier_data, tier_name, filename)
    } else {
        .get_interval_tier(tier_data, tier_name, filename)
    }
}

.get_interval_tier <- function(tier_data, tier_name, filename) {
    ## TODO Check if interval tier name starts dot .
    
    if (tier_data$label[1] == "") {
        tier_data$t1 <- tier_data$t1[-1]
        tier_data$t2 <- tier_data$t2[-1]
        tier_data$label <- tier_data$label[-1]
    }
    
    if (utils::tail(tier_data$label, 1) == "") {
        tier_data$t1 <- tier_data$t1[-length(tier_data$t1)]
        tier_data$t2 <- tier_data$t2[-length(tier_data$t2)]
        tier_data$label <- tier_data$label[-length(tier_data$label)]
    }
    
    tstart <- as.integer(round(tier_data$t1, 3) * 1000)
    tend   <- as.integer(round(tier_data$t2, 3) * 1000)
    mid_point <- as.integer((tstart + tend) / 2)
    order  <- seq_along(tier_data$label)

    ## build a list with fixed and dynamic names
    df_list <- list(
        file = filename,
        time = c(tstart, utils::tail(tend, 1))
    )

    ## dynamic columns
    df_list[[paste0(tier_name, "_label")]]  <- c(tier_data$label, NA)
    df_list[[paste0(tier_name, "_tstart")]] <- c(tstart, NA)
    df_list[[paste0(tier_name, "_tend")]]   <- c(tend, NA)
    df_list[[paste0(tier_name, "_tmid")]]   <- c(mid_point, NA)
    df_list[[paste0(tier_name, "_bound")]]  <- c(tstart, utils::tail(tend, 1))
    df_list[[paste0(tier_name, "_order")]]  <- c(order, NA)

    data.table::as.data.table(df_list, stringsAsFactors = FALSE)
}

.get_point_tier <- function(tier_data, tier_name, filename) {
    ## TODO Check if point tier name starts dot .
    df_list <- list(
        file = filename,
        time = as.integer(round(tier_data$t, 3) * 1000)
    )

    order  <- seq_along(tier_data$label)
    df_list[[paste0(".", tier_name, "_label")]]  <- tier_data$label        
    df_list[[paste0(".", tier_name, "_order")]]  <- order

    data.table::as.data.table(df_list, stringsAsFactors = FALSE)
}

.join_tg <- function(list) {
    Reduce(function(x, y) {data.table::merge.data.table(x, y, by = c("file", "time"), all = TRUE)}, list)
}

### ------------------------------------------------------------------
### PRAAT_TO_TABLE
### ------------------------------------------------------------------

praat_to_table <- function(textgrids) {
    
    ## collect files
    files <- .get_files(textgrids = textgrids)

    praat_objects <- list()

    praat_objects$f0 <- .get_f0(files$pitchtier)
    praat_objects$intensity <- .get_intensity(files$int)
    praat_objects$periodicity_index <- .get_periodicity(files$pitch)
    praat_objects$textgrid <- .join_tg(.get_textgrids(files$tg))
    
    ## combine into one dataframe
    df <- Reduce(function(x, y) {data.table::merge.data.table(x, y, by = c("file", "time"), all = TRUE)},
                 praat_objects)

    ## Get rid of periodicity index values when there is no intensity
    df$periodicity_index[is.na(df$intensity_dB)] <- NA

    tg_cols <- names(praat_objects$textgrid)
    
    ## remove point tiers from selection
    no.point.tiers.names <- tg_cols[!startsWith(tg_cols, ".")]
    
    ## remove "file" and "time" columns from selection
    interval.tiers.names <- setdiff(no.point.tiers.names, c("file", "time"))

    ## identify interval tier columns only
    if (!is.null(textgrids)) {
        ## get name of textgrid columns
        tg_cols <- names(praat_objects$textgrid)
        ## remove point tiers from selection
        no_point_tiers_names <- tg_cols[!startsWith(tg_cols, ".")]
        ## remove "file" and "time" columns from selection
        interval_tiers_names <- setdiff(no_point_tiers_names, c("file", "time"))
        
        for (col in interval_tiers_names) {
            
            col_tend <- paste0(strsplit(col, "_")[[1]][1], "_tend")
            
            intervals <- df[!is.na(get(col)), .(
                                                  file,
                                                  start = time,
                                                  end =  get(col_tend),
                                                  value = get(col)
                                              )]
            
                                        # no intervals -> skip
            if (nrow(intervals) == 0L) next
            
                                        # set keys required for non-equi join
            setkeyv(intervals, c("file", "start", "end"))
            
                                        # assign value into column 'col' for rows whose time ∈ [start, end]
            df[intervals, on = .(file, time >= start, time <= end), (col) := i.value]
            
        }
    }

    ## restore row order by file and time
    df <- df[order(df$file, df$time), ]

    ## reset rownames
    rownames(df) <- NULL

    data.table::setkey(df, NULL)
    
    df
}


.unlog_intensity <- function(intensity_dB, digits = 9) {
  intensity_Pa <- round(4e-10 * 10^(intensity_dB / 10), digits)
  return(intensity_Pa)
}

get_periodic_energy <- function(
  intensity_dB, periodicity_index,
  perfloor = 0.01, threshold = 0.25
) {

  ## Convert intensity scale from dB SPL to Pascal
  intensity_Pa <- .unlog_intensity(intensity_dB)

  ## Scaling constants
  max_periodicity_index <- max(periodicity_index, na.rm = TRUE)
  max_periodic_energy_Pa <- max(intensity_Pa * periodicity_index, na.rm = TRUE)

  ## Apply threshold to periodicity_index
  periodicity_index[periodicity_index < (max_periodicity_index * threshold)] <- 0

  ## Compute periodic intensity
  periodic_energy_Pa <- intensity_Pa * periodicity_index

  ## Periodic intensity in dB
  periodic_energy_dB <- 10 * log10(periodic_energy_Pa / (max_periodic_energy_Pa * perfloor))

  ## Clean up invalid values
  periodic_energy_dB[is.na(periodic_energy_dB) | is.infinite(periodic_energy_dB) | periodic_energy_dB < 0] <- 0

  return(periodic_energy_dB)
}
