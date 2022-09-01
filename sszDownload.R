sszDownload <- function(outputId, label = "Download"){
  tags$a(id = outputId, class = "btn btn-default shiny-download-link chipDownload", href = "", 
         target = "_blank", download = NA, label)
}