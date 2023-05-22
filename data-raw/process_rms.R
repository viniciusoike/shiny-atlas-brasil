library(readxl)
library(here)
library(dplyr)
library(stringr)
library(tidyr)

#> Import dictionaries

dict_census <- read_excel(
  here("data-raw/dictionary_census.xlsx"),
  sheet = "subdictionary"
  )

dict_pnad <- read_excel(
  here("data-raw/dictionary_pnad.xlsx"),
  sheet = "subdictionary"
)

#> Import PNAD data base
pnad_dat <- read_excel(here("data-raw/ADH_BASE_RADAR_2012-2021.xlsx"))
#> Convert column names to lower
names(pnad_dat) <- tolower(names(pnad_dat))
#> Simplify and standardize metro names
pnad_dat <- pnad_dat %>%
  filter(agregacao == "RM_RIDE") %>%
  rename(name_metro = nome, year = ano) %>%
  mutate(
    name_metro = str_remove_all(name_metro, "(Região Metropolitana de)|\\(.+\\)"),
    name_metro = str_remove(name_metro, "Região Administrativa Integrada de Desenvolvimento da"),
    name_metro = str_trim(name_metro, side = "both")
  )

#> Drop some variables and convert to numeric
pnad_dat <- pnad_dat %>%
  select(-agregacao, -codigo) %>%
  mutate(across(idhm:popocup18m, as.numeric))

#> Compute population age-groups (0-15), (15-65), (65+)
pnad_dat <- pnad_dat %>%
  mutate(
    pop_young = popt - pop15m,
    pop_adult = pop15m - pop65m,
    pop_elder = pop65m
  )

#> Select only columns in the dictionary
pnad_dat <- pnad_dat %>%
  select(year, name_metro, all_of(dict_pnad$variable))

#> Import Census Data
#> OBS: there is both a 20 RMs Excel sheet and a 24 RMs Excel sheet
#> I import the more complete 24 RMs sheet.
census_dat <- read_excel(
  here("data-raw/dados_florianopolis/base final RM Florianขpolis/A - Base 24 RMs 2000_2010.xlsx")
  )

#> Convert column names to lower
names(census_dat) <- tolower(names(census_dat))

#> Drop full NA columns, standardize id columns and metro names
census_dat <- census_dat %>%
  select(where(~!any(is.na(.x)))) %>%
  rename(code_metro = codrm, name_metro = nome_rm, year = ano) %>%
  mutate(
    name_metro = stringr::str_remove(name_metro, " \\(.+\\)"),
    name_metro = stringr::str_remove(name_metro, "(RM )|(RIDE )"),
    name_metro = stringr::str_remove(name_metro, " e Litoral Norte"),
    name_metro = str_replace(name_metro, "Rio Janeiro", "Rio de Janeiro"),
    name_metro = str_replace(name_metro, "Teresina_Timon", "Grande Teresina")
  )

#> OBS: despite this, these data bases don't share the same metro regions

x1 <- unique(pnad_dat$name_metro)
x2 <- unique(census_dat$name_metro)
x1 = x1[order(x1)]
x2 = x2[order(x2)]

#> Select only variables in the dictionary and convert to numeric

#> Compute population columns

#> Select only columns that start with either mulh (female) and hom (male)
#> Convert to long format and remove "tot" (totals)
pop <- census_dat |> 
  select(code_metro, matches("(^mulh)|(^hom)")) |> 
  pivot_longer(cols = -code_metro, names_to = "age_group", values_to = "pop") |>
  filter(!str_detect(age_group, "tot"))

#> Get only the age [0-9]a[0-9] and sum to get total population values for each
#> age group. Split by a to get age_min and age_max
pop <- pop %>%
  mutate(age = str_remove_all(age_group, "(homem)|(homens)|(mulher)|(mulh)")) |> 
  summarise(total_pop = sum(pop, na.rm = TRUE), .by = c("code_metro", "age")) %>%
  separate("age", into = c("age_min", "age_max"), sep = "a", convert = TRUE)

#> Classify into broader age groups, sum again, and convert to wide
pop <- pop %>%
  mutate(
    age_group = case_when(
      age_min < 15 ~ "young",
      age_min >= 15 & age_min < 65 ~ "adult",
      age_min >= 65 ~ "elder"
    )
  ) %>%
  summarise(pop = sum(total_pop), .by = c("code_metro", "age_group")) %>%
  pivot_wider(
    id_cols = "code_metro",
    names_from = "age_group",
    names_prefix = "pop_",
    values_from = "pop"
    )

#> Join with original Census data
census_dat <- left_join(census_dat, pop, by = "code_metro")

#> Select only columns in the dictionary
census_dat <- census_dat %>%
  select(name_metro, year, all_of(dict_census$variable))

#> Stack tables
#> OBS: Census data runs through 2000 and 2010 while PNAD data runs through
#> 2012-2021
unique(census_dat$year)
unique(pnad_dat$year)

#> Convert some column names
census_dat <- census_dat %>%
  rename(anosest = e_anosestudo, poptot = pop)

dat <- rbind(census_dat, pnad_dat)
readr::write_csv(dat, here("data/rmdata.csv"))
readr::write_csv(dict_pnad, here("data/dict_rm.csv"))