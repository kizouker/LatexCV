import os
import json
import re
import nltk
from nltk.corpus import stopwords
from collections import Counter

# Säkerställ att nödvändiga nltk-resurser är nedladdade
nltk.download('punkt')
nltk.download('punkt_tab')  # Ladda ner den saknade resursen
try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('stopwords')

# Funktion för att generera ett strukturerat filnamn
def generate_filename(company, role, date):
    filename = f"{date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}.tex"
    print(f"Debug: Genererat filnamn: {filename}")
    return filename

# Funktion för att extrahera nyckelord från en jobbeskrivning
def extract_keywords(text, num_keywords=10):
    words = nltk.word_tokenize(text.lower())
    words = [word for word in words if word.isalnum()]
    
    try:
        stop_words = set(stopwords.words('swedish'))
    except LookupError:
        nltk.download('stopwords')
        stop_words = set(stopwords.words('swedish'))
    
    words = [word for word in words if word not in stop_words]
    keywords = [word for word, count in Counter(words).most_common(num_keywords)]
    print(f"Debug: Extraherade nyckelord: {keywords}")
    return keywords

# Funktion för att skapa JSON-metadata
def create_metadata(company, role, location, application_date, job_id, job_description, keywords):
    job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}"
    os.makedirs(job_folder, exist_ok=True)
    print(f"Debug: Skapad jobbmapp: {job_folder}")
    
    metadata = {
        "company": company,
        "role": role,
        "location": location,
        "application_date": application_date,
        "job_id": job_id,
        "status": "Pending",
        "response": "Not yet received",
        "follow_up_date": "TBD",
        "source": "Unknown",
        "notes": "",
        "extracted_keywords": keywords
    }
    
    filename = f"{job_folder}/metadata.json"
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=4, ensure_ascii=False)
    print(f"Debug: Metadata sparad till {filename}")

# Funktion för att spara vanliga intervjufrågor och svar
def save_interview_questions(role, questions, application_date, company):
    job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}"
    os.makedirs(job_folder, exist_ok=True)
    filename = f"{job_folder}/interview_questions.json"
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=4, ensure_ascii=False)
    print(f"Debug: Intervjufrågor sparade till {filename}")

# Funktion för att skapa filer om de inte redan finns
def ensure_file_exists(filename, content=""):
    if not os.path.exists(filename):
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Debug: Skapade fil: {filename}")
    else:
        print(f"Debug: Filen finns redan: {filename}")

# Funktion för att bearbeta jobbeskrivningar och skapa applikationer
def process_job_descriptions(job_description_dir="job_descriptions"):
    print(f"Debug: Använder mapp för jobbeskrivningar: {job_description_dir}")
    if not os.path.exists(job_description_dir):
        print(f"Jobbeskrivningsmappen '{job_description_dir}' finns inte.")
        return
    
    for filename in os.listdir(job_description_dir):
        if filename.endswith(".txt"):
            print(f"Debug: Bearbetar fil: {filename}")
            file_path = os.path.join(job_description_dir, filename)
            with open(file_path, 'r', encoding='utf-8') as f:
                job_description = f.read()
            
            # Extrahera jobbdetaljer från filnamnet
            parts = filename.replace(".txt", "").split("_")
            if len(parts) < 3:
                print(f"Debug: Ogiltigt filnamn, hoppar över: {filename}")
                continue
            
            application_date, company, role = parts[0], parts[1], "_".join(parts[2:])
            print(f"Debug: Extraherade detaljer - Datum: {application_date}, Företag: {company}, Roll: {role}")
            job_id = "Unknown"
            
            # Extrahera nyckelord från jobbeskrivningen
            keywords = extract_keywords(job_description)
            
            # Skapa metadata och nödvändiga filer
            create_metadata(company, role, "Unknown", application_date, job_id, job_description, keywords)
            job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}"
            ensure_file_exists(f"{job_folder}/cover_letter.tex", "% Cover Letter\n\n")
            ensure_file_exists(f"{job_folder}/cv.tex", "% CV\n\n")
            ensure_file_exists(f"{job_folder}/job_ad.txt", job_description)

            # Spara jobbeskrivningen i job_ad.txt
            job_ad_path = f"{job_folder}/job_ad.txt"
            with open(job_ad_path, 'w', encoding='utf-8') as job_ad_file:
                job_ad_file.write(job_description)
            print(f"Debug: Jobbeskrivning sparad i {job_ad_path}")
            
            # Spara extraherade nyckelord i en separat fil
            keywords_path = f"{job_folder}/keywords.txt"
            with open(keywords_path, 'w', encoding='utf-8') as keywords_file:
                keywords_file.write("\n".join(keywords))
            print(f"Debug: Extraherade nyckelord sparade i {keywords_path}")

# Exempel på anrop med en specifik subfolder
if __name__ == "__main__":
    # Ändra "din_subfolder" till den mapp du vill använda för jobbeskrivningar
    process_job_descriptions("job_descriptions/31_feb")
