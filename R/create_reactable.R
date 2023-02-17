#' bar_chart
#'
#' @description function to render a bar chart with label on the left within a reactable
#'
#' @param width defaults to "100%"
#' @param height defaults to "2rem"
#' @param fill defaults to "#00bfc4"
#' @param background defaults to NULL
#'
#' @return a div with the chart
bar_chart <- function(width = "100%", height = "2rem", fill = "#00bfc4", background = NULL) {
  bar <- div(style = list(background = fill, width = width, height = height))
  chart <- div(style = list(flexGrow = 1, marginLeft = "0rem", background = background), bar)
  div(style = list(display = "flex"), chart)
}

#' create_reactable
#'
#' @description function to create the main reactable output for the MPE app, given appropriate data
#'
#' @param filtered_data data appropriately filtered according to inputs
#' @param data_mietobjekt data to show in the main table
#'
#' @return reactable
create_reactable <- function(filtered_data, data_mietobjekt) {
  # prepare table for details (when clicked and expanded)
  data_detail <- filtered_data %>%
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
    mutate(Lagemass = fct_relevel(
      Lagemass,
      c("10. Perzentil", "25. Perzentil", "Median", "75. Perzentil", "90. Perzentil", "Durchschnitt")
    )) %>%
    arrange(Lagemass) %>%
    mutate(
      WertNum = as.numeric(Wert),
      Spacer = NA
    ) %>%
    select(GliederungLang, Lagemass, Wert, Spacer, Konfidenzintervall)

  table_output <- reactable(data_mietobjekt,
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
        sortable = FALSE
      ),
      WertNum = colDef(
        name = "Median",
        align = "right",
        minWidth = 50
      ),
      WertNum2 = colDef(
        name = "",
        align = "left",
        cell = function(value) {
          width <- paste0(value / max(data_mietobjekt$WertNum2) * 100, "%")
          bar_chart(width = width, fill = get_zuericolors("qual6", nth = 1))
        },
        class = "bar",
        headerClass = "barHeader"
      ),
      ci50 = colDef(
        name = "95 % Konfidenzintervall",
        align = "left",
        sortable = FALSE
      )
    ),
    details = function(index) {
      det <- filter(
        data_detail,
        GliederungLang == data_mietobjekt$GliederungLang[index]
      ) %>%
        select(-GliederungLang)
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
              headerClass = "spacerHeader"
            ),
            Konfidenzintervall = colDef(
              name = "95 % Konfidenzintervall",
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

  return(table_output)
}
