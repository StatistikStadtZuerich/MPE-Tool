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


data <- df %>% 
  mutate(EinheitLang = case_when(
    EinheitLang == "Wohnung" ~ "Mietpreis pro Wohnung",
    EinheitLang == "Quadratmeter" ~ "Mietpreis pro Quadratmeter"
  )) %>% 
  mutate(PreisartLang = case_when(
    PreisartLang == "Brutto" ~ "Bruttomiete",
    PreisartLang == "Netto" ~ "Nettomiete"
  )) %>% 
  mutate(ci = paste(qu50l, qu50u, sep = " bis "))


