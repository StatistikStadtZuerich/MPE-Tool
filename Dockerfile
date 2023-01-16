FROM rocker/tidyverse:4.2.1
RUN install2.r rsconnect shiny reactable jpeg httr data.table Rcpp openxlsx
WORKDIR /home/mpe-test
COPY app.R app.R
COPY R/ssz_download_excel.R R/ssz_download_excel.R
COPY www/logo_stzh_stat_sw_pos_1.png www/logo_stzh_stat_sw_pos_1.png
COPY R/get_data.R R/get_data.R
COPY R/sszDownload.R R/sszDownload.R
COPY www/sszTheme.css www/sszTheme.css
COPY www/Titelblatt.xlsx www/Titelblatt.xlsx
COPY deploy.R deploy.R
CMD Rscript deploy.R