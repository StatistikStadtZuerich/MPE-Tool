# Load Library
library(shiny)
library(reactable)
library(dplyr)
library(lubridate)
library(icons)
library(xlsx)

# Source Donwload Function
source("sszDownload.R", local = TRUE)

# Source Data Load
source("prepareData.R", local = TRUE)

# Set the Icon path
icon <- icon_set("icons/")

# Example Data
data <- flights %>% 
    mutate(date = ymd(paste(year, month, day, sep = "-"))) %>%
    select(tailnum, date, dest, origin, distance) %>% 
    sample_n(300)

# Define UI
ui <- fluidPage(
    
    # Include CSS
    includeCSS("sszTheme.css"),
    
    # Application Title 
    titlePanel("MPE App"),
    
    # Sidebar: Input widgets are placed here
    sidebarLayout(
        sidebarPanel(
            
            # Example selectInput()
            selectInput("select", "Geografischer Raum:", 
                        choices = unique(df$RaumeinheitLang),
                        selected = "Ganze Stadt"),
            
            # Example radioButtons() vertical
            tags$div(
                class = "radioDiv",
                radioButtons(inputId = "ButtonGroupLabel",
                             label = "Typ der Wohnung:",
                             choices = unique(data$GemeinnuetzigLang),
                             selected = "Nicht gemeinnützig" # default value
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
            
            # Example radioButtons() 2
            tags$div(
                class = "radioDiv",
                radioButtons(inputId = "ButtonGroupLabel3",
                             label = "Ebene Mietpreis:",
                             choices = unique(data$EinheitLang),
                             selected = "Mietpreis pro Quadratmeter" # default value
                )
            ),
            
            # Example radioButtons() 2
            tags$div(
                class = "radioDiv",
                radioButtons(inputId = "ButtonGroupLabel4",
                             label = "Anzahl Zimmer:",
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
        ),
        
        
        # Mail Panel: Outputs are placed here
        mainPanel(
            
            # Define subtitle
            tags$div(
                class = "infoDiv",
                p("Die untenstehenden Mietobjekte entsprechen Ihren Suchkriterien. Für Detailinformationen wählen Sie eine Art der Mietobjekte aus.")
            ),
            hr(),
        
            # Example Table Output 
            reactableOutput("table"),
            
           
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
    
    
    # Reactable Output
    output$table <- renderReactable({
        tableOutput <- reactable(filteredData() %>% 
                                     select(GliederungLang, mean, qu50, ci),
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
                                 defaultColDef = colDef(
                                     align = "left",
                                     minWidth = 50
                                 ),
                                 theme = reactableTheme(
                                     borderColor = "#DEDEDE"
                                 ),
                                 outlined = TRUE,
                                 highlight = FALSE,
                                 defaultPageSize = 10,
                                 onClick = "select",
                                 selection = "single",
                                 rowClass = JS("function(rowInfo) {return rowInfo.selected ? 'selected' : ''}"),
                                 rowStyle = JS("function(rowInfo) {if (rowInfo.selected) { return { backgroundColor: '#F2F2F2'}}}")
        )
    })
    
    
    # Render data download
    # CSV
    output$csvDownload <- downloadHandler(
        filename = function() {
            paste("data-", Sys.Date(), ".csv", sep="")
        },
        content = function(file) {
            write.csv(filteredData(), file)
        }
    )
    
    # Excel
    output$excelDownload <- downloadHandler(
        filename = function() {
            paste("data-", Sys.Date(), ".xlsx", sep="")
        },
        content = function(file) {
            write.xlsx(filteredData(), file)
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)