# Load Library
library(shiny)
library(tidyverse)
library(reactable)
library(lubridate)
library(jpeg)
library(openxlsx)
library(readxl)
library(httr)
library(data.table)
library(zuericssstyle)

# Source Data Load
source("R/get_data.R")
data <- get_data()

# Source Export Excel
source("R/ssz_download_excel.R")

# source function to create main output table
source("R/create_reactable.R")

# if data load didn't work show message
if(is.null(data)) {
  
  # Define UI
  ui <- fluidPage(
    
    # Include CSS
    includeCSS("www/sszThemeShiny.css"),
    
    h1("Fehler"),
    p("Aufgrund momentaner Wartungsarbeiten ist die Applikation zur Zeit nicht verfügbar.")
  )
  
  # Server function
  server <- function(input, output) {}
  
  # Run the application 
  shinyApp(ui = ui, server = server)
  
}else{
  # Define UI
  ui <- fluidPage(
    
    # Include CSS
    includeCSS("www/sszThemeShiny.css"),
    
    # Sidebar: Input widgets are placed here
    sidebarLayout(
      sidebarPanel(
        
        # dropdown for selecting "raum": stadt/kreis/quartiergruppen/quartier
        sszSelectInput("select_raum", "Geografischer Raum:", 
                       choices = unique(data$RaumeinheitLang),
                       selected = "Ganze Stadt"),
        
        conditionalPanel(
          condition = 'input.select_raum != "Quartiere"',
          
          # radio button Wohnungstyp (ALLE/gemeinnuetzig/nicht gemeinnuetzig)
          sszRadioButtons(inputId = "radio_gemeinnue_alle",
                       label = "Typ der Wohnung:",
                       choices = unique(data$GemeinnuetzigLang)
          )
        ),
        
        conditionalPanel(
          condition = 'input.select_raum == "Quartiere"',
          
          # radio button gemeinnuetzig oder nicht
          sszRadioButtons(inputId = "radio_gemeinnue",
                       label = "Typ der Wohnung:",
                       choices = "Alle Wohnungen",
                       selected = "Alle Wohnungen" # default value
          )
        ),
        
        # radio button Anzahl Zimmer
        sszRadioButtons(inputId = "radio_anz_zi",
                     label = "Anzahl Zimmer:",
                     choices = unique(data$ZimmerLang),
                     selected = "3 Zimmer" # default value
        ),
        
        # Preis pro Wohnung oder pro Quadratmeter
        sszRadioButtons(inputId = "radio_whg_qm",
                     label = "Ebene Mietpreis:",
                     choices = unique(data$EinheitLang),
                     selected = "Mietpreis pro Quadratmeter" # default value
        ),
        
        # Netto oder Bruttopreise
        sszRadioButtons(inputId = "radio_net_gross",
                     label = "Art der Miete:",
                     choices = unique(data$PreisartLang),
                     selected = "Nettomiete" # default value
        ),
        
        # Action Button (disappears after first click)
        conditionalPanel(
          condition = 'input.action_start==0',
          
          sszActionButton("action_start",
                       "Abfrage starten")
        ),
        
        #  Download panel with 3 download buttons
        conditionalPanel(
          condition = 'input.action_start',
          h3("Daten herunterladen"),
          # Download Panel
          tags$div(
            id = "downloadWrapperId",
            class = "downloadWrapperDiv",
            sszDownload("csvDownload",
                        label = "csv"
            ),
            sszDownload("excelDownload",
                        label = "xlsx"
            ),
            sszOgdDownload(inputId = "ogdDown",
                           label = "OGD",
                           onclick = "window.open('https://data.stadt-zuerich.ch/dataset/bau_whg_mpe_mietpreis_raum_zizahl_gn_jahr_od5161', '_blank')"
            )
          )
        )
      ),
      
      
      # Mail Panel: Outputs are placed here
      mainPanel(
        
        conditionalPanel(
          condition = 'input.action_start>0',
          
          # Title for table
          h1("Die untenstehenden Mietpreise entsprechen Ihren Suchkriterien"),
          hr(),
          # Define subtitle
          tags$div(
            class = "infoDiv",
            p("Für Detailinformationen zur Verteilung der geschätzten Mietpreise wählen Sie eine Zeile aus (alle Angaben in CHF/Monat).")
          )
        ),
        
        # Example Table Output 
        reactableOutput("table")
      )
    )
  )
  
  
  # Server function
  server <- function(input, output, session) {
    
    # First button click to activate search, after not necessary anymore
    global <- reactiveValues(activeButton = FALSE)
    
    observeEvent(input$action_start, {
      req(input$action_start)
      global$activeButton <- TRUE
    })
    
    # Filter data according to inputs
    filteredData <- reactive({
      req(global$activeButton == TRUE)
      
      if(input$select_raum == "Quartiere") {
        filtered <- data %>%
          filter(RaumeinheitLang == input$select_raum) %>% 
          filter(ZimmerLang == input$radio_anz_zi) %>% 
          filter(EinheitLang == input$radio_whg_qm) %>% 
          filter(PreisartLang == input$radio_net_gross) 
        filtered
      } else {
        filtered <- data %>%
          filter(RaumeinheitLang == input$select_raum) %>% 
          filter(GemeinnuetzigLang == input$radio_gemeinnue_alle) %>% 
          filter(ZimmerLang == input$radio_anz_zi) %>% 
          filter(EinheitLang == input$radio_whg_qm) %>% 
          filter(PreisartLang == input$radio_net_gross) 
        filtered
      }
    })
    
    output$table <- renderReactable({
      
      # Prepare df
      data_mietobjekt <- filteredData() %>% 
        mutate(WertNum2 = as.numeric(qu50)) %>%
        mutate(WertNum = as.numeric(qu50)) %>% 
        select(GliederungLang, WertNum, WertNum2, ci50) 

      table_output <- create_reactable(filteredData(), data_mietobjekt)
    })
    
    filteredData_excel <- reactive({
      
      
      filtered <- filteredData() %>%
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
      filtered
    })
    
    
    # Render data download
    # CSV
    output$csvDownload <- downloadHandler(
      filename = function() {
        paste("MPE-", Sys.Date(), ".csv", sep="")
      },
      content = function(file) {
        write.csv(filteredData(), file, fileEncoding = "UTF-8")
      }
    )
    
    # Excel
    output$excelDownload <- downloadHandler(
      filename = function() {
        paste("MPE-", Sys.Date(), ".xlsx", sep="")
      },
      content = function(file) {
        sss_download_excel(filteredData_excel(), file, input$select_raum, input$radio_gemeinnue_alle, input$radio_anz_zi, input$radio_whg_qm, input$radio_net_gross)
      }
    )
  }
  
  # Run the application 
  shinyApp(ui = ui, server = server)
}
