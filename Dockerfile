FROM rocker/tidyverse:4.2.1
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
COPY install_deps_for_deployment.R install_deps_for_deployment.R
CMD Rscript install_deps_for_deployment.R
CMD Rscript -e "installed.packages()"
#CMD Rscript deploy.R