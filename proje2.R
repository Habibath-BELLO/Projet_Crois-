


data <- read.csv("/home/UCA/nakonate/projet_croise/Tokyo_Wheather_Start.csv")

data

install.packages("dplyr")
install.packages("tidyr")
library(dplyr)
library(tidyr)


#pour voir si y'a des données manquante :

is.na(data)

#pour enlever les na : 
donne <- na.omit(data)

donne

#pour voir la structure des données

str(donne)
# Convertir la colonne 'date' en type Date 

donne$Date <- as.Date(donne$Date, format= "%d/%m/%Y")

View(donne)
# Si l'heure est présente dans une colonne séparée, vous pouvez aussi la convertir

donne$Hour <- hms::as_hms(donne$Hour)

str(donne)

donne
View(donne)
# Si vous voulez regrouper par date et calculer la moyenne ou d'autres mesures
data_group <- donne %>%
  group_by(Date) %>%
  summarise(
    #heure_moyenne=mean(Hour),
    temperature_moyenne = mean(Temperature), 
    humidite_moyenne = mean(Humidity),  
    vent_moyenne = mean(Wind.speed),  
    nb_observations = n()  # Nombre d'observations par jour
  )

# Afficher le résultat
print(data_group)




data1 <- read.table("~/projet_croise/Tokyo_Scooter_Rental_Start(1).txt", quote="\"", comment.char="")
data1


is.na(data1)

#pour enlever les na : 
donne1 <- na.omit(data1)


donne1
#pour voir la structure des données

str(donne1)


# Charger les bibliothèques nécessaires
library(dplyr)
library(tidyr)



# Séparer la colonne datetime en deux nouvelles colonnes : Date et Heure
separated <- donne1 %>%
  separate(V1, into = c("Date", "Heure"), sep = " ")  # " " est le séparateur entre la date et l'heure

# Convertir la colonne Date en format Date
separated$Date <- as.Date(separated$Date)

# Afficher le résultat
print(separated)

View(separated)


# Si l'heure est présente dans une colonne séparée, vous pouvez aussi la convertir

separated$Heure <- hms::as_hms(separated$Heure)

separated_group <- separated %>%
  group_by(Date) %>%
  summarise(
    #heure_moyenne=mean(Heure),
    nb_observations = n()  # Nombre d'observations par jour
  )

print(separated_group)


# Fusion des deux data par la colonne Date

data_fusion <- merge(data_group, separated_group, by = "Date")
data_fusion
