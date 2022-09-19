### Required packages
packages <- c("tidyverse",
              "httr",
              "parallel",
              "data.table",
              "lubridate")

### Load packages
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

### Load Data

# TODO: Change data load to OGD (data is only available from the Filer right now)
df <- read.csv("O:/Publikationen/7_Webartikel/2022/WEB_010_2022_Mietpreiserhebung/3_Ergebnisse/OGD_Export.csv",
               sep = ";", encoding = "UTF-8" )

# ##URL
# URL <- c("https://gist.githubusercontent.com/DonGoginho/c5f003f5f27a52d15f3e149c99f88e58/raw/32fa3baca067cd262ca187ed5dc793b02944b852/BAU516OD5161.csv")
# 
# ##Download
# dataDownload <- function(link) {
#   data <- data.table::fread(link,
#                             encoding = "UTF-8")
# }
# 
# #Parallelisation
# cl <- makeCluster(detectCores())
# clusterExport(cl, "URL")
# data <- parLapply(cl, URL, dataDownload)
# stopCluster(cl)
# 
# 
# ##Data
# df <- data[[1]]

# always have one decimal
specify_decimal <- function(x, k) trimws(format(round(x, 1), nsmall=1))

data <- df %>% 
  mutate(EinheitLang = case_when(
    EinheitLang == "Wohnung" ~ "Mietpreis pro Wohnung",
    EinheitLang == "Quadratmeter" ~ "Mietpreis pro Quadratmeter"
  )) %>% 
  mutate(PreisartLang = case_when(
    PreisartLang == "Brutto" ~ "Bruttomiete",
    PreisartLang == "Netto" ~ "Nettomiete"
  )) %>% 
  mutate_at(vars(starts_with("qu"), starts_with("mean")), specify_decimal) %>%
  mutate(ci10 = paste(qu10l, qu10u, sep = " bis ")) %>% 
  mutate(ci25 = paste(qu25l, qu25u, sep = " bis ")) %>% 
  mutate(ci50 = paste(qu50l, qu50u, sep = " bis ")) %>% 
  mutate(ci75 = paste(qu75l, qu75u, sep = " bis ")) %>% 
  mutate(ci90 = paste(qu90l, qu90u, sep = " bis ")) 
  

