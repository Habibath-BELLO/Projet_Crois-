import requests
import csv
import re
import time
import os

# --- Configuration ---
base_url = "http://172.22.215.130:8100/?id={}&token=D_57b8d745"
csv_file = 'infos.csv'
id_file = 'last_ID_infos.txt'

max_errors = 3  
requests_per_second = 10  
sleep_time = 0.4  
pause_interval = 300  
pause_time = 5  
error_pause_time = 360  # 2 minutes de pause après une erreur

# --- Vérification et initialisation de l'ID ---
if os.path.exists(id_file):
    with open(id_file, 'r', encoding='utf-8') as file:
        last_id = file.read().strip()
        current_id = int(last_id) if last_id.isdigit() else 1
else:
    current_id = 1  # Si le fichier n'existe pas, on commence à 1

# --- Vérification du fichier CSV et chargement des ID existants ---
existing_data = set()
if os.path.exists(csv_file):
    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.reader(file)
        for row in reader:
            existing_data.add(tuple(row))
else:
    open(csv_file, 'w').close()  # Création du fichier s'il n'existe pas

# --- Ouverture du fichier CSV en mode ajout ---
with open(csv_file, 'a', newline='', encoding='utf-8') as file:
    writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar='\7')

    with requests.Session() as session:
        error_count = 0  # Compteur d'erreurs

        while True:
            batch_data = []

            for _ in range(requests_per_second):
                url = base_url.format(current_id)

                try:
                    response = session.get(url, timeout=5)

                    if response.status_code == 200:
                        error_count = 0  # Réinitialisation des erreurs

                        page_text = response.text
                        cleaned_text = page_text.replace(".000Z", "")

                        segments = re.split(r'T', cleaned_text)
                        filtered_segments = [
                            segment.strip().replace("Date_Hour", "").replace("Date", "").replace("Seasons", "")
                            .replace("Holiday", "").replace("Functioning.Day", "").replace(" : ", "")
                            for segment in segments if segment.strip()
                        ]
                        filtered_segments = [segment.replace(',', ' ').strip() for segment in filtered_segments]

                        if filtered_segments and tuple(filtered_segments) not in existing_data:
                            batch_data.append(filtered_segments)  # Suppression de l'ID dans les données enregistrées
                            existing_data.add(tuple(filtered_segments))

                        # Mise à jour du dernier ID réussi
                        with open(id_file, 'w', encoding='utf-8') as f:
                            f.write(str(current_id))

                        print(f"✅ ID {current_id} récupéré avec succès.")

                    elif response.status_code == 404:
                        print(f"❌ L'ID {current_id} n'existe pas. Arrêt du script.")
                        exit()

                    else:
                        print(f"⚠️ Erreur {response.status_code} pour l'ID {current_id}. Passage au suivant.")
                        error_count += 1  

                except requests.exceptions.RequestException as e:
                    print(f"❌ Erreur de connexion pour l'ID {current_id}: {e}")
                    error_count += 1  

                # Si une erreur survient, sauvegarde de l'ID et pause avant de réessayer
                if error_count >= 1:
                    print(f"🚨 Erreur détectée. Sauvegarde de l'ID et pause de {error_pause_time} secondes.")
                    with open(id_file, 'w', encoding='utf-8') as f:
                        f.write(str(current_id))
                    time.sleep(error_pause_time)  # Pause avant de réessayer
                    error_count = 0  # Réinitialisation du compteur

                current_id += 1  # Passage à l'ID suivant

                # Pause après un certain nombre de requêtes
                if current_id % pause_interval == 0:
                    print(f"⏸️ Pause de {pause_time} seconde(s) après {pause_interval} ID.")
                    time.sleep(pause_time)

            # Écriture des nouvelles données récupérées
            for row in batch_data:
                writer.writerow(row)

            time.sleep(sleep_time)
