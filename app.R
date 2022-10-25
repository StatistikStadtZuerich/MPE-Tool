# Load Library
library(shiny)
library(tidyverse)
library(reactable)
library(lubridate)
library(icons)
library(xlsx)
library(jpeg)
library(imager)
library(openxlsx)
library(readxl)
library(httr)
library(parallel)
library(data.table)


# Source Donwload Function
source("sszDownload.R", encoding = "UTF-8")

# Source Data Load
source("prepareData.R", encoding = "UTF-8")

# Source Export Excel
source("prepareExcel/exportExcel.R", encoding = "UTF-8")

# Set the Icon path
icon <- icon_set("icons/")

# if data load didn't work show message
if(is.null(data)) {
    
    # Define UI
    ui <- fluidPage(
        
        # Include CSS
        includeCSS("sszTheme.css"),
        
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
        includeCSS("sszTheme.css"),
        
        # Application Title 
        #titlePanel("MPE App"),
        
        # Sidebar: Input widgets are placed here
        sidebarLayout(
            sidebarPanel(
                
                # Example selectInput()
                selectInput("select", "Geografischer Raum:", 
                            choices = unique(data$RaumeinheitLang),
                            selected = "Ganze Stadt"),
                
                conditionalPanel(
                    condition = 'input.select != "Quartiere"',
                
                    # Example radioButtons() vertical
                    tags$div(
                        class = "radioDiv",
                        radioButtons(inputId = "ButtonGroupLabel",
                                     label = "Typ der Wohnung:",
                                     choices = unique(data$GemeinnuetzigLang)
                        )
                    )
                ),
                
                conditionalPanel(
                    condition = 'input.select == "Quartiere"',
                    
                    # Example radioButtons() vertical
                    tags$div(
                        class = "radioDiv",
                        radioButtons(inputId = "ButtonGroupLabel1",
                                     label = "Typ der Wohnung:",
                                     choices = c("Alle Wohnungen"),
                                     selected = "Alle Wohnungen" # default value
                        )
                    )
                ),
                
                
                
                # Example radioButtons() 2
                tags$div(
                    class = "radioDiv",
                    radioButtons(inputId = "ButtonGroupLabel2",
                                 label = "Anzahl Zimmer:",
                                 choices = unique(data$ZimmerLang),
                                 selected = "3 Zimmer" # default value
                    )
                ),
                
                # Example radioButtons() 3
                tags$div(
                    class = "radioDiv",
                    radioButtons(inputId = "ButtonGroupLabel3",
                                 label = "Ebene Mietpreis:",
                                 choices = unique(data$EinheitLang),
                                 selected = "Mietpreis pro Quadratmeter" # default value
                    )
                ),
                
                # Example radioButtons() 4
                tags$div(
                    class = "radioDiv",
                    radioButtons(inputId = "ButtonGroupLabel4",
                                 label = "Art der Miete:",
                                 choices = unique(data$PreisartLang),
                                 selected = "Nettomiete" # default value
                    )
                ),
                
                # Action Button (disappears after first click)
                conditionalPanel(
                    condition = 'input.ActionButtonId==0',
                    
                    actionButton("ActionButtonId",
                                 "Abfrage starten")
                ),
                conditionalPanel(
                    condition = 'input.ActionButtonId>0',
                    
                ),
                
                
                # Example Download Button
                conditionalPanel(
                    condition = 'input.ActionButtonId',
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
                        actionButton(inputId = "ogdDown",
                                     label = "OGD",
                                     onclick ="window.open('https://data.stadt-zuerich.ch/', '_blank')"
                        )
                    )
                )
            ),
            
            
            # Mail Panel: Outputs are placed here
            mainPanel(
                
                conditionalPanel(
                    condition = 'input.ActionButtonId>0',
                    
                    # Title for table
                    h1("Die untenstehenden Mietpreise entsprechen Ihren Suchkriterien"),
                    hr(),
                    # Define subtitle
                    tags$div(
                        class = "infoDiv",
                        p("Für Detailinformationen zur Verteilung der geschätzten Mietpreise wählen Sie eine Zeile aus (alle Angaben in CHF/Monat).")
                    )
                ),
                conditionalPanel(
                    condition = 'input.ActionButtonId==0',
                    
                ),
            
                # Example Table Output 
                reactableOutput("table")
               
            )
        )
    )
    
    
    # Server function
    server <- function(input, output) {
        
        # First button click to activate search, after not necessary anymore
        global <- reactiveValues(activeButton = FALSE)
        
        observeEvent(input$ActionButtonId, {
            req(input$ActionButtonId)
            global$activeButton <- TRUE
        })
        
        # Filter data according to inputs
        filteredData <- reactive({
            req(global$activeButton == TRUE)
            
            filtered <- data %>%
                filter(RaumeinheitLang == input$select) %>% 
                filter(GemeinnuetzigLang == input$ButtonGroupLabel) %>% 
                filter(ZimmerLang == input$ButtonGroupLabel2) %>% 
                filter(EinheitLang == input$ButtonGroupLabel3) %>% 
                filter(PreisartLang == input$ButtonGroupLabel4) 
            filtered
        })
        
        
        output$table <- renderReactable({
            
            # Render a bar chart with a label on the left
            bar_chart <- function(width = "100%", height = "2rem", fill = "#00bfc4", background = NULL) {
                bar <- div(style = list(background = fill, width = width, height = height))
                chart <- div(style = list(flexGrow = 1, marginLeft = "1.0rem", background = background), bar)
                div(style = list(display = "flex"), chart)
            }
        
            # Prepare df
            if(input$ButtonGroupLabel3 == "Mietpreis pro Quadratmeter"){
                data_mietobjekt <- filteredData() %>% 
                    mutate(WertNum2 = as.numeric(qu50)) %>%
                    mutate(WertNum = as.numeric(qu50)) %>% 
                    select(GliederungLang, WertNum, WertNum2, ci50) 
            }else{
                data_mietobjekt <- filteredData() %>% 
                    mutate(WertNum2 = as.numeric(qu50)) %>%
                    mutate(WertNum = as.integer(qu50)) %>% 
                    select(GliederungLang, WertNum, WertNum2, ci50)
            }
             
    
            data_detail <- filteredData() %>% 
                dplyr::select(GliederungLang, starts_with("qu"), mean, starts_with("ci")) %>%
                gather(key, value, -GliederungLang) %>% 
                mutate(Art = case_when(
                    startsWith(key, "qu") ~ "Wert",
                    startsWith(key, "mean") ~ "Wert",
                    startsWith(key, "ci") ~ "Konfidenzintervall"
                )) %>% 
                mutate(Lagemass = case_when(
                    key == "qu10" ~ "10. Perzentil",
                    key == "qu25" ~ "25. Perzentil",
                    key == "qu50" ~ "Median",
                    key == "qu75" ~ "75. Perzentil",
                    key == "qu10" ~ "90. Perzentil",
                    key == "qu90" ~ "90. Perzentil",
                    key == "ci10" ~ "10. Perzentil",
                    key == "ci25" ~ "25. Perzentil",
                    key == "ci50" ~ "Median",
                    key == "ci75" ~ "75. Perzentil",
                    key == "ci90" ~ "90. Perzentil",
                    key == "mean" ~ "Durchschnitt",
                    key == "cimean" ~ "Durchschnitt"
                )) %>% 
                select(-key) %>%
                spread(Art, value) %>%
                mutate(Lagemass = fct_relevel(Lagemass, c("10. Perzentil", "25. Perzentil", "Median", "75. Perzentil", "90. Perzentil", "Durchschnitt"))) %>% 
                arrange(Lagemass) %>% 
                mutate(WertNum = as.numeric(Wert),
                       Spacer = NA) %>% 
                select(GliederungLang, Lagemass, Wert, Spacer, Konfidenzintervall)
            
            tableOutput2 <- reactable(data_mietobjekt,
                                      paginationType = "simple",
                                      language = reactableLang(
                                          noData = "Keine Einträge gefunden",
                                          pageNumbers = "{page} von {pages}",
                                          pageInfo = "{rowStart} bis {rowEnd} von {rows} Einträgen",
                                          pagePrevious = "\u276e",
                                          pageNext = "\u276f",
                                          pagePreviousLabel = "Vorherige Seite",
                                          pageNextLabel = "Nächste Seite"
                                      ),
                                      theme = reactableTheme(
                                          borderColor = "#DEDEDE"
                                      ),
                                      outlined = TRUE,
                                      highlight = TRUE,
                                      columns = list(
                                          GliederungLang = colDef(
                                              name = "Gliederung",
                                              minWidth = 50,
                                              sortable = FALSE),
                                          WertNum = colDef(
                                              name = "Median",
                                              align = "right",
                                              minWidth = 50),
                                          WertNum2 = colDef(
                                              name = "",
                                              align = "left",
                                              cell = function(value) {
                                                  width <- paste0(value / max(data_mietobjekt$WertNum2) * 100, "%")
                                                  bar_chart(width = width, fill = "#3e46dd")
                                              },
                                              class = "bar",
                                              headerClass = "barHeader"),
                                          ci50 = colDef(
                                              name = "Konfidenzintervall",
                                              align = "left"
                                          )),
                                      details = function(index) {
                                          det <- filter(data_detail, GliederungLang == data_mietobjekt$GliederungLang[index]) %>% select(-GliederungLang)
                                          htmltools::div(
                                              class = "Details",
                                              reactable(det, 
                                                        class = "innerTable",
                                                        outlined = TRUE,
                                                        fullWidth = TRUE,
                                                        borderless = TRUE,
                                                        theme = reactableTheme(
                                                            borderColor = "#DEDEDE"
                                                        ),
                                                        columns = list(
                                                            Lagemass = colDef(
                                                                name = "Lagemass",
                                                                align = "left",
                                                                minWidth = 50,
                                                                sortable = FALSE
                                                            ),
                                                            Wert = colDef(
                                                                name = "Wert",
                                                                align = "right",
                                                                minWidth = 50,
                                                                sortable = FALSE
                                                            ),
                                                            Spacer = colDef(
                                                                name = "",
                                                                align = "left",
                                                                minWidth = 100,
                                                                sortable = FALSE,
                                                                class = "spacer",
                                                                headerClass = "spacerHeader"),
                                                            Konfidenzintervall = colDef(
                                                                name = "Konfidenzintervall",
                                                                minWidth = 100,
                                                                sortable = FALSE
                                                            )
                                                            
                                                        )
                                                        
                                              )
                                          )
                                      },
                                      onClick = "expand",
                                      defaultPageSize = 15
            )
            tableOutput2
        })
        
        filteredData_excel <- reactive({
            
            
            filtered <- filteredData() %>%
                rename(Jahr = StichtagDatJahr,
                       Raumeinheit = RaumeinheitLang,
                       Gliederung = GliederungLang,
                       Zimmer = ZimmerLang,
                       Gemeinnützig = GemeinnuetzigLang,
                       Einheit = EinheitLang,
                       Preisart = PreisartLang,
                       Durchschnittspreis = mean,
                       `95. KI (Durchschnittspreis)` = cimean,
                       `Preis 10. Perzentil` = qu10,
                       `95. KI (10. Perzentil)` = ci10,
                       `Preis 25. Perzentil` = qu25,
                       `95. KI (25. Perzentil)` = ci25,
                       Medianpreis = qu50,
                       `95. KI (Medianpreis)` = ci50,
                       `Preis 75. Perzentil` = qu75,
                       `95. KI (75. Perzentil)` = ci75,
                       `Preis 90. Perzentil` = qu90,
                       `95. KI (90. Perzentil)` = ci90) %>% 
                select(-ends_with("Sort"), -StichtagDatMonat)
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
                sszDownloadExcel(filteredData_excel(), file, input$select, input$ButtonGroupLabel, input$ButtonGroupLabel2, input$ButtonGroupLabel3, input$ButtonGroupLabel4)
            }
        )
    }
    
    # Run the application 
    shinyApp(ui = ui, server = server)
}
