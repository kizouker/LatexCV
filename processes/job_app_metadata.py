import os
import json
import re
import nltk
from nltk.corpus import stopwords
from collections import Counter

# Ensure nltk resources are downloaded
nltk.download('punkt')
try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('stopwords')

# Function to generate a structured filename
def generate_filename(company, role, date):
    return f"{date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}.tex"

# Function to extract keywords from job description
def extract_keywords(text, num_keywords=10):
    words = nltk.word_tokenize(text.lower())
    words = [word for word in words if word.isalnum()]
    
    try:
        stop_words = set(stopwords.words('swedish'))
    except LookupError:
        nltk.download('stopwords')
        stop_words = set(stopwords.words('swedish'))
    
    words = [word for word in words if word not in stop_words]
    return [word for word, count in Counter(words).most_common(num_keywords)]

# Function to create JSON metadata
def create_metadata(company, role, location, application_date, job_id, job_description, keywords):
    job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-') }"
    os.makedirs(job_folder, exist_ok=True)
    
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
    print(f"Metadata saved to {filename}")

# Function to store common interview questions and answers
def save_interview_questions(role, questions, application_date, company):
    job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-') }"
    os.makedirs(job_folder, exist_ok=True)
    filename = f"{job_folder}/interview_questions.json"
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=4, ensure_ascii=False)
    print(f"Interview questions saved to {filename}")

# Function to create missing files
def ensure_file_exists(filename, content=""):
    if not os.path.exists(filename):
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)
    print(f"Ensured file exists: {filename}")

# Function to process job descriptions and create applications
def process_job_descriptions(job_description_dir="job_descriptions"):
    job_description_dir = "job_descriptions"
    if not os.path.exists(job_description_dir):
        print("Job descriptions folder does not exist.")
        return
    
    for filename in os.listdir(job_description_dir):
        if (filename.endswith(".txt")) :
            file_path = os.path.join(job_description_dir, filename)
            with open(file_path, 'r', encoding='utf-8') as f:
                job_description = f.read()
            
            # Extract job details from filename
            parts = filename.replace(".txt", "").split("_")
            if len(parts) < 3:
                print(f"Skipping invalid filename format: {filename}")
                continue
            
            application_date, company, role = parts[0], parts[1], "_".join(parts[2:])
            job_id = "Unknown"
            
            # Extract keywords from job description
            keywords = extract_keywords(job_description)
            
            # Create metadata and files
            create_metadata(company, role, "Unknown", application_date, job_id, job_description, keywords)
            job_folder = f"Applications/{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-') }"
            ensure_file_exists(f"{job_folder}/cover_letter.tex", "% Cover Letter\n\n")
            ensure_file_exists(f"{job_folder}/cv.tex", "% CV\n\n")
            ensure_file_exists(f"{job_folder}/job_ad.txt", job_description)

            # Save job description in job_ad.txt
            job_ad_path = f"{job_folder}/job_ad.txt"
            with open(job_ad_path, 'w', encoding='utf-8') as job_ad_file:
                job_ad_file.write(job_description)
            print(f"Job description saved to {job_ad_path}")
            
            # Save extracted keywords to a separate file
            keywords_path = f"{job_folder}/keywords.txt"
            with open(keywords_path, 'w', encoding='utf-8') as keywords_file:
                keywords_file.write("\n".join(keywords))
            print(f"Extracted keywords saved to {keywords_path}")


# Exempel på anrop med en specifik subfolder
if __name__ == "__main__":
    # Ändra "din_subfolder" till den mapp du vill använda
    process_job_descriptions("31_feb")