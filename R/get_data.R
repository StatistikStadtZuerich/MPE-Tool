#' get_data
#' 
#' @description function to download and prepare the data from the OGD portal for the MPE app
#'
#' @return data (tibble) if successful, NULL if not
#' @export
#'
#' @examples
get_data <- function() {
  
  # By default the data frame is empty
  data <- NULL
  
  URL <- "https://data.stadt-zuerich.ch/dataset/bau_whg_mpe_mietpreis_raum_zizahl_gn_jahr_od5161/download/BAU516OD5161.csv"
  
  tryCatch(                       # Applying tryCatch
    
    expr = {                      # Specifying expression
      
      df <- data.table::fread(URL, encoding = "UTF-8")
      
      # always have one decimal
      specify_decimal <- function(x, k) trimws(format(round(x, 1), nsmall = 1))
      
      data_prep <- df %>% 
        mutate(EinheitLang = case_when(
          EinheitLang == "Wohnung" ~ "Mietpreis pro Wohnung",
          EinheitLang == "Quadratmeter" ~ "Mietpreis pro Quadratmeter"
        )) %>% 
        mutate(PreisartLang = case_when(
          PreisartLang == "Brutto" ~ "Bruttomiete",
          PreisartLang == "Netto" ~ "Nettomiete"
        )) 
      
      # Only round() when EinheitSort is "Preis pro Quadratmeter"
      data_qm <- data_prep %>% 
        filter(EinheitSort == 2) %>% 
        mutate_at(vars(starts_with("qu"), starts_with("mean")), specify_decimal) %>% 
        mutate_at(vars(starts_with("qu"), starts_with("mean")), as.character)
      
      data_whg <- data_prep %>% 
        filter(EinheitSort == 1) %>% 
        mutate_at(vars(starts_with("qu"), starts_with("mean")), as.character)
      
      data <- data_qm %>%
        bind_rows(data_whg) %>% 
        mutate(ci10 = paste(qu10l, qu10u, sep = " bis ")) %>% 
        mutate(ci25 = paste(qu25l, qu25u, sep = " bis ")) %>% 
        mutate(ci50 = paste(qu50l, qu50u, sep = " bis ")) %>% 
        mutate(ci75 = paste(qu75l, qu75u, sep = " bis ")) %>% 
        mutate(ci90 = paste(qu90l, qu90u, sep = " bis ")) %>% 
        mutate(cimean = paste(meanl, meanu, sep = " bis ")) %>% 
        select(-ends_with("u"), -ends_with("l")) %>% 
        select(StichtagDatJahr, StichtagDatMonat, RaumeinheitSort, RaumeinheitLang, GliederungSort, 
               GliederungLang, ZimmerSort, ZimmerLang, GemeinnuetzigSort, GemeinnuetzigLang, EinheitSort, 
               EinheitLang, PreisartSort, PreisartLang, mean, cimean, qu10, ci10, qu25, ci25, qu50, ci50,
               qu75, ci75, qu90, ci90, Domain, Sample1, Sample2)
      
      rm(df, data_prep, data_qm, data_whg)
      
      return(data)
      
    },
    
    error = function(e){          # Specifying error message
      message("Error in Data Load")
      return(data)
    },
    
    warning = function(w){        # Specifying warning message
      message("Warning in Data Load")
    }
  )
}
