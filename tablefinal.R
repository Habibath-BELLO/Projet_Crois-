setwd("C:/Users/andre/projet")

#packages utilisés (il faut les installer au préalable avec "install.packages("nompackages")")
library(ggplot2)
library(tidyverse)
library(dplyr)
library(factoextra)
library(FactoMineR)

#Chargement des fichiers
data_meteo <- read.delim("./meteo.csv", header = FALSE, skip = 1)
data_loc <- read.csv("./locations.csv", header = FALSE, skip = 1)
data_infos <- read.delim("./infos.csv", header = FALSE, skip = 1)

#Mettre le format date a la colonne date et supression de la deuxième date inutile
data_infos<-data_infos %>%
  mutate(V1 = as.Date(V1)) %>%
  mutate(V2 = NULL)
#Garder une date par evenement météo, transformation au format Date
data_meteo <- data_meteo %>%
  mutate(V1 = as.Date(V1)) %>%
  distinct(V1, .keep_all = TRUE) %>% 
  mutate(V2=NULL) %>% 
  mutate(V3=NULL)
#Garder une ligne par date et calcul de nombre de locations faites par jour
data_loc<- data_loc %>%
  mutate(V1 = as.Date(V1)) %>% 
  group_by(V1) %>%
  summarize(V2 = n())
#Regroupement des 3 table en une
data_final<- data_meteo %>%
  full_join(data_infos, by = "V1") %>%
  full_join(data_loc, by = "V1")
colnames(data_final)=c("Date","Temperature","%Humidité","Vitesse du vent(m/s)","Visibilité","Temperature des points de rosé","Radiation solaire","Chute de pluie","Chute de neige","saison","vacance","Jour de Travail","Nombre de Trotinette loué")

#Supression des lignes avec des valeurs manquantes transformé les réponces oui et non par des 1 et 0 et création des noms des colonnes
#et changer les saison pour les avoir toujours remplie car il y avait des troues et les avoir en français
data_final=na.omit(data_final)
  data_final<- data_final %>%
    mutate(vacance= ifelse(`Jour de Travail` == "Yes","No","Yes")) %>% 
    mutate(saison = case_when(
      month(Date) %in% c(12, 1, 2) ~ "Hiver",
      month(Date) %in% c(3, 4, 5) ~ "Printemps",
      month(Date) %in% c(6, 7, 8) ~ "Été",
      month(Date) %in% c(9, 10, 11) ~ "Automne")) %>% 
    mutate(`Chute de pluie`=as.numeric(`Chute de pluie`)) %>% 
    mutate(Temperature=as.numeric(Temperature)) %>% 
    mutate(`Temperature des points de rosé`=as.numeric(`Temperature des points de rosé`)) %>% 
    mutate(`Chute de neige`=as.numeric(`Chute de neige`))

#Création d'un graphique avec un nuage de point et la ligne régression linéaire en rouge
ggplot(data_final, aes(x = Temperature, y = `Nombre de Trotinette loué`)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Impact de la température sur les locations", x = "Température (°C)", y = "Nombre de trottinettes louées") +
  theme_minimal()


#Création histogramme avec le nombre de trotinette loué au cours du temps
ggplot(data_loc,aes(x=data_loc$V1,y=data_loc$V2))+
  geom_bar(stat = "identity") +
  labs(title = "Nombre de Trotinette loué au fils du temps", x = "Date", y = "Nombre de trottinettes louées")+
  theme_minimal()

#création d'un graphe qui compare le nombre de trotinette loué en fonction de la météo
ggplot(data_final, aes(x = Date)) +
  geom_line(aes(y = `Nombre de Trotinette loué`, color = "Nombre de location du jour"), size = 1, alpha = 0.8) +
  geom_point(data = subset(data_final, `Chute de pluie` > 0), 
             aes(y = `Nombre de Trotinette loué`, color = "Jour de pluie")) +
  geom_point(data = subset(data_final, `Chute de neige` > 0), 
             aes(y = `Nombre de Trotinette loué`, color = "Jour de neige")) +
  scale_color_manual(values = c("Nombre de location du jour" = "black", "Jour de pluie" = "blue", "Jour de neige" = "aquamarine3")) +
  labs(title = "comparaison du nombre de trotinette loué en fonction de la météo",
       x = "Date",
       y = "Nombre de locations",
       color = "Légende") +
  theme_minimal()


#création visualisation de l'ACP
colnames(data_meteo)=c("Date","Temperature","%Humidité","Vitesse du vent(m/s)","Visibilité","Temperature des points de rosée","Radiation solaire","Chute de pluie","Chute de neige")
data_meteo=data_meteo
data_meteo=na.omit(data_meteo) %>% 
  mutate(Date = NULL)
acp_result <- PCA(data_meteo, scale.unit = TRUE, graph = FALSE)
fviz_pca_var(acp_result, col.var = "contrib",
             gradient.cols = c("blue", "red"),
             repel = TRUE, 
             title = "ACP des Variables Météo")

data_final=as.data.frame(data_final)
write.table(x=data_final,file = "bdd_update.csv",row.names = FALSE)
  
