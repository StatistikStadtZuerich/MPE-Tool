# Authenticate
rsconnect::setAccountInfo(name = Sys.getenv("SHINY_ACC_NAME"),
               token = Sys.getenv("TOKEN"),
               secret = Sys.getenv("SECRET"))
# Deploy
rsconnect::deployApp(forceUpdate = TRUE)