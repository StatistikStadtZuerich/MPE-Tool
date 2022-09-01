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
            
            # Example textInput()
            textInput("suchfeld", "Name:"),
            
            # Example dateRangeInput()
            dateRangeInput("DateRange", "Datum:",
                           start  =  min(data$date), # default start date
                           end    =  max(data$date), # default end date
                           min    =  min(data$date), # minimum allowed date
                           max    =  max(data$date), # maximum allowed date
                           format = "dd.mm.yyyy",
                           language = "de",
                           separator = icon("calendar")),
            
            # Example selectInput()
            selectInput("select", "Destination:", 
                        choices = unique(data$dest),
                        selected = "LAX"),
            
            # Example radioButtons() vertical
            tags$div(
                class = "radioDiv",
                radioButtons(inputId = "ButtonGroupLabel",
                             label = "Flughafen:",
                             choices = unique(data$origin),
                             selected = "JFK" # default value
                )
            ),
            
            # Example actionButton()
            actionButton(inputId = "ActionButtonId",
                         label = "Abfrage starten"),
            
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
            
            # Example Title h1
            h1("Titel der Tabelle"),
            hr(),
            
            # Example Table Output 
            reactableOutput("table"),
            
            # Example Title h2
            h2("Untertitel des Outputs"),
            
            # Example Title h3
            h3("Unter-Untertitel des Outputs"),
            
            # Example Text Paragraph
            p("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."),
            
        )
    )
)


# Server function
server <- function(input, output) {
    
    
    # Filter data according to inputs
    filteredData <- reactive({
        
        # Filter: No Search
        if(input$suchfeld == "") {
            filtered <- data %>%
                dplyr::filter(date >= input$DateRange[1] & date <= input$DateRange[2]) %>% 
                filter(dest == input$select) %>% 
                filter(origin == input$ButtonGroupLabel) 
            
            filtered
            
            # Filter: With Search   
        } else {
            filtered <- data %>%
                filter(grepl(input$suchfeld, tailnum, ignore.case=TRUE)) %>%
                dplyr::filter(date >= input$DateRange[1] & date <= input$DateRange[2]) %>% 
                filter(dest == input$select) %>% 
                filter(origin == input$ButtonGroupLabel)
            
            filtered
            
        }
    })
    
    
    # Reactable Output
    output$table <- renderReactable({
        tableOutput <- reactable(filteredData(),
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
                                 defaultPageSize = 5,
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