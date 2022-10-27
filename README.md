# MPE-Tool
Shiny app for MPE tool (MietPreisErhebung). By using the this application you agree to the disclaimer.

The MPE application on the website of [Statistik Stadt Zürich](https://www.stadt-zuerich.ch/prd/de/index/statistik.html) shows estimated average rental prices in the city of Zurich (including prices per square meter, median and the respective quantiles) of 2-, 3- and 4-room rental apartments as of the date of April 1, 2022. The estimated rental prices are based on a stratified sample. On the one hand this sample consist of a non-representative ad hoc sample established over several years, which is collected quarterly (net rental prcies for 50,572 apartments). On the other hand, it consists of a one-time random sample of all remaining rental apartments, which guarantees the necessary representativeness (net rental prices for 5236 apartments).

In addition to the number of rooms, the rents can also be filtered according to different spatial levels, and in some cases also according to two different categories of property developers (profit oriented and non-profit oriented) and market indicators (tenancies categorized by duration).

The MPE does not record any information on the standard of fit-out, condition, exposure, noise situation or other rent-relevant factors for the apartments.

The data is obtained from the Open Data portal of the city of Zurich and is available [here](https://data.stadt-zuerich.ch/dataset?tags=mpe).

## Glossary
### Rental apartments in the population
The population in the MPE consits of all 2-, 3- and 4-room apartments in the city of Zurich that are offered for rent unfurnished and without specified restrictions on the possible tenant base. Apartmentes that are only offered to a limited group of people are considered to be apartments in retirement homes, student apartments such as those of the [Studentische Wohngenossenschaft Zürich (WOKO)](https://www.woko.ch/), as well as service and staff apartments of asylums, hospitals, hospitality industry and the like. Furnished apartments are apartments that are known to be rented out on a commercial basis for a limited period of time.

### Non-profit status
First of all, non-profit apartments include all apartments owned by the City of Zurich or by cooperatives, associations or foundations and and are managed according to the principle of cost rent. Furthermore, the category of non-profit includes apartments whose ownership is considered non-profit in the broader sense and does not rent its rental properties exclusively according to the principle of cost rent (certain foundations, associations and stock corporations). The cost rent is used to pay the interest on debts and the administrative costs, as well as to ensure the maintenance and value retention of the properties and the provisions for renewal. In the medium to long term, the cost rent results in lower rents than for comparable properties on the housing market.

### Market indicators
The market indicators characterize the type of tenancy. The following five categories are distinguished:

- New built rents. Rents in buildings that are no more than two years old.
- Reference rents: Tenancy with duration ≤ 2 years in older buildings.
- Existing rents 2-10 years: Tenancy with duration > 2 and ≤ 10 years.
- Existing rents 11-20 years: Tenancy with duration > 10 and ≤ 20 years.
- Existing rents over 20 years: Tenancy with duration > 20 years.

### Spatial unit: city quarters
Because city quarters are too small as spatial unit for a sample survey as the MPE, it is not possible to differentiate rents by non-profit status.

### Spacial unit: city quarters group


## Architecture

```mermaid
flowchart LR;
  f1[F1 select area]:::filter --> button[button start]:::button
  f2[F2 select type of apartment]:::filter --> button
  f3[F3 select number of rooms]:::filter --> button
  f4[F4 select level of rental price]:::filter --> button
  f5[F5 select net or gros price]:::filter --> button
  button --> output1[(filtered data = \nF1 + F2 + F3 + F4 + F5)]:::data
  output1 --> results1[[Resultat rent prices]]:::result
  results1 --> f6[F6 select level]:::filter
  f6 --> output2[(output1 + F6)]:::data
  output2 --> results2[["Resultat Level \n(show percentiles \nand confidence \ninterval)"]]:::result
  output2 --> downloads{Downloads}:::download
  
  classDef filter fill:#ffff2f,stroke:#ffff2f,color:#000000;
  classDef button fill:#695eff,stroke:#695eff,color:#000000;
  classDef data fill:#edade6,stroke:#acb0b0,color:#000000;
  classDef result fill:#59e6f0,stroke:#acb0b0,color:#000000;
  classDef download fill:#43cc4c,stroke:#43cc4c,color:#000000;
```
