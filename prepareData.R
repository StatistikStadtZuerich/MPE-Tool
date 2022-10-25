### Required packages
#packages <- c("tidyverse",
#"httr",
#       #      "parallel",
#             "data.table",
#             "lubridate")

### Load packages
#package.check <- lapply(
# packages,
# FUN = function(x) {
#   if (!require(x, character.only = TRUE)) {
#     install.packages(x, dependencies = TRUE)
#     library(x, character.only = TRUE)
#   }
# }
#)

# https://gist.githubusercontent.com/DonGoginho/2ea874a3e8c36457635bbb0f6eedaed3/raw/d9060f682bc773b06fbb07ac16f2788d6a7247f2
# https://data.integ.stadt-zuerich.ch/dataset/int_dwh_bau_whg_mpe_mietpreis_raum_zizahl_gn_jahr_od5161/download/BAU516OD5161.csv

### Load Data
# # TODO: Change data load to OGD (data is only available from the Filer right now)
# df <- read.csv("O:/Publikationen/7_Webartikel/2022/WEB_010_2022_Mietpreiserhebung/03_Ergebnisse/OGD_Export.csv",
#                sep = ",", encoding = "UTF-8" ) %>%
#   rename(StichtagDatJahr = X.U.FEFF.StichtagDatJahr)


# By default the data frame is empty
data <- NULL
tryCatch(                       # Applying tryCatch
  
  expr = {                      # Specifying expression

    # URL
    URL <- c("https://data.integ.stadt-zuerich.ch/dataset/int_dwh_bau_whg_mpe_mietpreis_raum_zizahl_gn_jahr_od5161/download/BAU516OD5161.csv")
    
    # Download
    dataDownload <- function(link) {
      data <- data.table::fread(link,
                                encoding = "UTF-8")
    }
    
    #Parallelisation
    cl <- makeCluster(detectCores())
    clusterExport(cl, "URL")
    data <- parLapply(cl, URL, dataDownload)
    stopCluster(cl)
    
    
    ##Data
    df <- data[[1]]
    
    # always have one decimal
    specify_decimal <- function(x, k) trimws(format(round(x, 1), nsmall=1))
    
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
    dataQuadrmpreis <- data_prep %>% 
      filter(EinheitSort == 2) %>% 
      mutate_at(vars(starts_with("qu"), starts_with("mean")), specify_decimal) %>% 
      mutate_at(vars(starts_with("qu"), starts_with("mean")), as.character)
    
    dataWhgpreis <- data_prep %>% 
      filter(EinheitSort == 1) %>% 
      mutate_at(vars(starts_with("qu"), starts_with("mean")), as.character)
    
    data <- dataQuadrmpreis %>%
      bind_rows(dataWhgpreis) %>% 
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
      
    rm(df, data_prep, dataQuadrmpreis, dataWhgpreis)

  },
  
  error = function(e){          # Specifying error message
    message("Error in Data Load")
    return(NULL)
  },
  
  warning = function(w){        # Specifying warning message
    message("Warning in Data Load")
  }
)
