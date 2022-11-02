# Authenticate
rsconnect::setAccountInfo(name = Sys.getenv("SHINY_ACC_NAME"),
               token = Sys.getenv("TOKEN"),
               secret = Sys.getenv("SECRET"))
# Deploy
rsconnect::deployApp(forceUpdate = TRUE,
                     appName = Sys.getenv("APP_NAME"))

# adjust memory size to extra large
rsconnect::configureApp(Sys.getenv("APP_NAME"),
                        size = "3xlarge")