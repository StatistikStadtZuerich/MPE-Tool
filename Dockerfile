FROM rocker/tidyverse:4.2.1
RUN install2.r shiny reactable lubridate jpeg httr data.table Rcpp openxlsx readxl pak
RUN Rscript -e "pak::pkg_install('StatistikStadtZuerich/zuericssstyle')"
RUN Rscript -e "pak::pkg_install('StatistikStadtZuerich/zuericolors')"
RUN Rscript -e "pak::pkg_install('mitchelloharawild/icons')"
RUN Rscript -e "pak::pkg_install('rstudio/rsconnect')" # need latest version, posit dropped support for previous
RUN Rscript -e "packageVersion('rsconnect')"
WORKDIR /home/mpe-test
COPY app.R app.R
COPY R/ssz_download_excel.R R/ssz_download_excel.R
COPY R/create_reactable.R R/create_reactable.R
COPY R/filter_data_for_excel.R R/filter_data_for_excel.R
COPY R/get_data.R R/get_data.R
COPY www/logo_stzh_stat_sw_pos_1.png www/logo_stzh_stat_sw_pos_1.png
COPY www/sszThemeShiny.css www/sszThemeShiny.css
COPY www/MPETheme.css www/MPETheme.css
COPY www/Titelblatt.xlsx www/Titelblatt.xlsx
COPY www/icons/download.svg www/icons/download.svg
COPY www/icons/external-link.svg www/icons/external-link.svg
COPY deploy.R deploy.R
CMD Rscript deploy.R