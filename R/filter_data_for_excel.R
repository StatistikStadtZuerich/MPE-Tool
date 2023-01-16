#' filter_data_for_excel
#' 
#' @description function to filter the data for the excel download table
#'
#' @param filtered_data 
#'
#' @return filtered tsibble
filter_data_for_excel <- function(filtered_data) {
  filtered_data %>%
    rename(Jahr = StichtagDatJahr,
           `Raum-einheit` = RaumeinheitLang,
           Gliederung = GliederungLang,
           Zimmer = ZimmerLang,
           `Gemein-nützigkeit` = GemeinnuetzigLang,
           `Ebene Mietpreis` = EinheitLang,
           `Art der Miete` = PreisartLang,
           `Durch-schnitts-preis` = mean,
           `Preis 10. Perzentil` = qu10,
           `Preis 25. Perzentil` = qu25,
           `Median-preis` = qu50,
           `Preis 75. Perzentil` = qu75,
           `Preis 90. Perzentil` = qu90,
           `Konfidenz-intervall Durch-schnitt` = cimean,
           `Konfidenz-intervall 10. Perzentil` = ci10,
           `Konfidenz-intervall 25. Perzentil` = ci25,
           `Konfidenz-intervall Median` = ci50,
           `Konfidenz-intervall 75. Perzentil` = ci75,
           `Konfidenz-intervall 90. Perzentil` = ci90,
           `Total Wohnungen (Domain)` = Domain,
           `Anzahl Wohnungen in Sample 1` = Sample1,
           `Anzahl Wohnungen in Sample 2` = Sample2) %>% 
    select(Jahr, `Raum-einheit`, Gliederung, Zimmer, `Gemein-nützigkeit`, `Ebene Mietpreis`,
           `Art der Miete`, `Durch-schnitts-preis`, `Preis 10. Perzentil`, `Preis 25. Perzentil`,
           `Median-preis`, `Preis 75. Perzentil`, `Preis 90. Perzentil`, 
           `Konfidenz-intervall Durch-schnitt`, `Konfidenz-intervall 10. Perzentil`, `Konfidenz-intervall 25. Perzentil`,
           `Konfidenz-intervall Median`, `Konfidenz-intervall 75. Perzentil`, `Konfidenz-intervall 90. Perzentil`,
           `Total Wohnungen (Domain)`, `Anzahl Wohnungen in Sample 1`, `Anzahl Wohnungen in Sample 2`)
}