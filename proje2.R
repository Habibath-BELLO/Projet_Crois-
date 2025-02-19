
install.packages("tidyr")

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
    heure_moyenne=mean(Heure),
    nb_observations = n()  # Nombre d'observations par jour
  )

print(separated_group)



