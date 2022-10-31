FROM rocker/tidyverse:4.0.3
RUN install2.r rsconnect shiny tidyverse reactable lubridate jpeg readxl httr data.table Rcpp remotes
RUN Rscript -e "remotes::install_github('ycphs/openxlsx')"
WORKDIR /home/mpe-test
COPY app.R app.R
COPY exportExcel.R exportExcel.R
COPY logo_stzh_stat_sw_pos_1.png logo_stzh_stat_sw_pos_1.png
COPY prepareData.R prepareData.R
COPY sszDownload.R sszDownload.R
COPY sszTheme.css sszTheme.css
COPY Titelblatt.xlsx Titelblatt.xlsx
COPY deploy.R deploy.R
CMD Rscript deploy.R