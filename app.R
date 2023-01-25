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
library(icons)

# Set the Icon path
ssz_icons <- icon_set("www/icons/")

# Source Data Load
source("R/get_data.R")
data <- get_data()

# Source Export Excel
source("R/ssz_download_excel.R")

# source function to create main output table
source("R/create_reactable.R")

# source function to filter data for the excel download
source("R/filter_data_for_excel.R")

# if data load didn't work show message
if (is.null(data)) {
  
  # Define UI
  ui <- fluidPage(
    
    # Include CSS
    includeCSS("www/sszThemeShiny.css"),
    includeCSS("www/MPETheme.css"),
    
    h1("Fehler"),
    p(paste0("Aufgrund momentaner Wartungsarbeiten ist die Applikation ",
             "zur Zeit nicht verfügbar."))
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
    includeCSS("www/MPETheme.css"),
    
    # Sidebar: Input widgets are placed here
    sidebarLayout(
      sidebarPanel(
        
        # dropdown for selecting "raum": stadt/kreis/quartiergruppen/quartier
        sszSelectInput("select_raum", "Geografischer Raum", 
                       choices = unique(data$RaumeinheitLang),
                       selected = "Ganze Stadt"),
        
        conditionalPanel(
          condition = 'input.select_raum != "Quartiere"',
          
          # radio button Wohnungstyp (ALLE/gemeinnuetzig/nicht gemeinnuetzig)
          sszRadioButtons(inputId = "radio_gemeinnue_alle",
                       label = "Typ der Wohnung",
                       choices = unique(data$GemeinnuetzigLang)
          )
        ),
        
        conditionalPanel(
          condition = 'input.select_raum == "Quartiere"',
          
          # radio button gemeinnuetzig oder nicht
          sszRadioButtons(inputId = "radio_gemeinnue",
                       label = "Typ der Wohnung",
                       choices = "Alle Wohnungen",
                       selected = "Alle Wohnungen" # default value
          )
        ),
        
        # radio button Anzahl Zimmer
        sszRadioButtons(inputId = "radio_anz_zi",
                     label = "Anzahl Zimmer",
                     choices = unique(data$ZimmerLang),
                     selected = unique(data$ZimmerLang)[[2]] # default value
        ),
        
        # Preis pro Wohnung oder pro Quadratmeter
        sszRadioButtons(inputId = "radio_whg_qm",
                     label = "Ebene Mietpreis",
                     choices = unique(data$EinheitLang),
                     selected = unique(data$EinheitLang)[[1]] # default value
        ),
        
        # Netto oder Bruttopreise
        sszRadioButtons(inputId = "radio_net_gross",
                     label = "Art der Miete",
                     choices = unique(data$PreisartLang),
                     selected = unique(data$PreisartLang)[[1]] # default value
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
            sszDownloadButton("csv_download",
                        label = "csv",
                        image = img(ssz_icons$download)
            ),
            sszDownloadButton("excel_download",
                        label = "xlsx",
                        image = img(ssz_icons$download)
            ),
            sszOgdDownload(outputId = "ogd_download",
                           label = "OGD",
                           href = paste0(
                             "https://data.stadt-zuerich.ch/dataset/", 
                             "bau_whg_mpe_mietpreis_raum_zizahl_gn_jahr_od5161"),
                           image = img(ssz_icons("external-link"))
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
          p(paste0("Für Detailinformationen zur Verteilung der geschätzten ", 
                     "Mietpreise wählen Sie eine Zeile aus (alle Angaben in ", 
                     "CHF/Monat)."))
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
    filtered_data <- reactive({
      req(global$activeButton == TRUE)
      
      if (input$select_raum == "Quartiere") {
        filtered1 <- data
      } else {
        filtered1 <- data %>%
          filter(GemeinnuetzigLang == input$radio_gemeinnue_alle) 
      }
      
      filtered1 %>% 
        filter(RaumeinheitLang == input$select_raum) %>% 
        filter(ZimmerLang == input$radio_anz_zi) %>% 
        filter(EinheitLang == input$radio_whg_qm) %>% 
        filter(PreisartLang == input$radio_net_gross)
    })
    
    output$table <- renderReactable({
      
      # Prepare df
      data_mietobjekt <- filtered_data() %>% 
        mutate(WertNum2 = as.numeric(qu50)) %>%
        mutate(WertNum = as.numeric(qu50)) %>% 
        select(GliederungLang, WertNum, WertNum2, ci50) 

      table_output <- create_reactable(filtered_data(), data_mietobjekt)
    })
    
    filtered_data_excel <- reactive({
      
      filter_data_for_excel(filtered_data())
      
    })
    
    
    # Render data download
    # CSV
    output$csv_download <- downloadHandler(
      filename = function() {
        paste("MPE-", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        write.csv(filtered_data(), file, fileEncoding = "UTF-8")
      }
    )
    
    # Excel
    output$excel_download <- downloadHandler(
      filename = function() {
        paste("MPE-", Sys.Date(), ".xlsx", sep = "")
      },
      content = function(file) {
        ssz_download_excel(
          filtered_data_excel(), 
          file, 
          input$select_raum, 
          input$radio_gemeinnue_alle, 
          input$radio_anz_zi, 
          input$radio_whg_qm, 
          input$radio_net_gross
          )
      }
    )
  }
  
  # Run the application 
  shinyApp(ui = ui, server = server)
}
