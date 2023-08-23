# Authenticate
rsconnect::setAccountInfo(name = Sys.getenv("SHINY_ACC_NAME"),
               token = Sys.getenv("TOKEN"),
               secret = Sys.getenv("SECRET"))

# use the old way of finding dependencies; can be removed with update or R version in Dockerfile and development
options(rsconnect.packrat = TRUE)

# Deploy
rsconnect::deployApp(forceUpdate = TRUE,
                     appName = Sys.getenv("APP_NAME"),
                     appFiles = c(
                       "R",
                       "www",
                       "app.R"
                     ))