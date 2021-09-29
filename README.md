# Portfolio
This portfolio is a compilation of notebooks and scripts I created for data analysis and exploration.

## SQL
**[AnAge Database of Animal Ageing and Longevity](https://github.com/mikebeccaria/portfolio/blob/main/Anage.sql)**:
This project explores the data of the Database of animal aging and logevity found here: https://genomics.senescence.info/species/index.html
I imported the data into a SQL database and made a few discoveries

**[Pregnancies, Births and Abortions in the United States](https://github.com/mikebeccaria/portfolio/blob/main/NationalAndStatePregnancy_PublicUse_Calcuations.sql)**:
A simple project dig into SQL a bit. This project explores data on pregnancies, births and abortions to discover which states had higher pregnancy rates for women under the age of 20 than the US average for years 2000-2017.

## Python/Pandas/etc.
**[Global Offshore Wind Turbine Dataset](https://github.com/mikebeccaria/portfolio/blob/74daf597b6c53753200523c45c5dba3263e05309/Global%20Offshore%20Wind%20Turbine%20Dataset%20ETL%20Project.ipynb)**:
The global offshore wind turbine dataset was posted October 4, 2021 and provides "geocoded information on global offshore wind turbines (OWTs) derived from Sentinel-1 synthetic aperture radar (SAR) time-series images from 2015 to 2019. It identified 6,924 wind turbines comprising of more than 10 nations." This notebook extracts the data from the dataset's Shapefile and transforms it to be uploadable to flourish to make a racing bar chart. Dataset: https://figshare.com/articles/dataset/Global_offshore_wind_farm_dataset/13280252/5 Flourish Graphic: https://public.flourish.studio/visualisation/7385349/

**[The Central Limit Theorem test](https://github.com/mikebeccaria/portfolio/blob/main/central_limit_theorum.ipynb)**:
This project tests the Central Limit Theorem in statistics using a height/weight data set and subsamples to determine if it is reliable to use a subsample of data to extrapolate information about the greater data set. The Central Limit Theorem is used everywhere, but perhaps most notably in polling, and states "that if you have a population with mean μ and standard deviation σ and take sufficiently large random samples from the population with replacement , then the distribution of the sample means will be approximately normally distributed." Does it work? Let's explore.

**[The Let's Make a Deal test](https://github.com/mikebeccaria/portfolio/blob/main/LetsMakeADeal.ipynb)**:
In the game show "Let's Make a Deal" from the 1980's, the host Monty Hall presents contestants with the option to win a prize that is hidden behind one of three doors. Behind the two other doors is a valueless prize. When a contestant chooses a door (let's say door #1), Monty then reveals one of the other two doors that does not contain the major prize (let's say door #3) and then asks the contestant if they would like to stay with their original selection (door #1) or switch to the unrevealed door (door #2). Will switching increase your odds of winning? This python script uses python Class, Function, and a bit of logic and numpy to find out.
