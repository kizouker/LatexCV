import os
import getpass
import json
import subprocess
import openai
from datetime import datetime
from CVGenerator import CVGenerator 

class BitwardenManager:
    def __init__(self, email):
        self.email = email
        self.session = None
import os
import json
import subprocess
import getpass

class BitwardenManager:
    def __init__(self, email):
        self.email = email
        print("BW_SESSION: ", os.getenv("BW_SESSION"))
        self.session = os.getenv("BW_SESSION")  # Försök hämta redan sparad session


    def is_session_valid(self):
        if not self.session:
            return False
        
        
        command = ["bw", "status"]

        env = os.environ.copy()
        env["BW_SESSION"] = self.session
        result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=30)
        if result.returncode != 0:
            return False
        try:
            status_data = json.loads(result.stdout)
            # Kontrollera att status inte är "locked"
            return status_data.get("status", "").lower() != "locked"
        except Exception:
            return False

    def login(self):
        """Logs in to Bitwarden and sets the session token."""
        if self.session and self.is_session_valid():
            print("Redan inloggad, använder sparad session.")
            return self.session
        
        print("Logging in to Bitwarden...")
        password = getpass.getpass("Ange ditt huvudlösenord för Bitwarden: ")
        login_command = ["bw", "login", self.email, "--raw"]
        # Skicka in lösenordet via stdin
        result = subprocess.run(login_command, input=password, capture_output=True, text=True, timeout=60)
      
        if result.returncode != 0:
            print("Error logging in to Bitwarden:", result.stderr)
            return None
        self.session = result.stdout.strip()
        os.environ["BW_SESSION"] = self.session  # Save for later use
        print("Bitwarden session obtained.")
        return self.session

    def get_secret(self, item_id, field_name="oauth_key"):
        """Retrieves a secret from a Bitwarden item using its ID."""
        if not self.session:
            self.login()
        env = os.environ.copy()

        print("BW_SESSION: ", self.session)
        
        env["BW_SESSION"] = self.session
        command = ["bw", "get", "item", item_id]
        result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=90)
        if result.returncode != 0:
            print("Error retrieving item from Bitwarden:", result.stderr)
            return None

        item_data = json.loads(result.stdout)
        # Justera enligt din Bitwarden-objektsstruktur.
        for field in item_data.get("fields", []):
            if field.get("name") == field_name:
                secret = field.get("value")
                print(f"Secret '{field_name}' retrieved from Bitwarden.")
                return secret

        # Alternativt, om hemligheten finns i "password"-fältet:
        if "password" in item_data:
            print("Secret retrieved from the 'password' field.")
            return item_data["password"]

        print("Secret not found in the Bitwarden item.")
        return None




# Example usage:
if __name__ == "__main__":
    # --- Bitwarden secret retrieval ---
    bw_email = "raberg@duck.com"
    #bw_item_id = "datcuf-cawwy0-Pinvat"  # Update this with your actual item id
    bw_item_id = "OpenAI_API_KEY"

    bw_manager = BitwardenManager(bw_email)
    openai_key = bw_manager.get_secret(bw_item_id)
    if not openai_key:
        print("Failed to retrieve OpenAI key from Bitwarden.")
        exit(1)

    # --- CV and Cover Letter Generation ---
    cv_gen = CVGenerator(openai_api_key=openai_key)

    # Example data for the application
    application_date = datetime.now().strftime("%Y-%m-%d")
    company = "IKEA"
    role = "IT Cyber Engineer"

    # Create folder structure for the application
    app_folder = cv_gen.create_file_structure(application_date, company, role)

    # Optionally, save metadata
    metadata = {
        "company": company,
        "role": role,
        "application_date": application_date,
        "status": "Pending",
        "notes": "",
        "source": "Bitwarden",
    }
    cv_gen.save_metadata(app_folder, metadata)

    # Define prompts for generating documents
    cover_letter_prompt = (
        "Generate a cover letter for an IT Cyber Engineer applying to IKEA. "
        "Focus on skills in cybersecurity, IT management, and innovative problem solving."
    )
    cv_prompt = (
        "Generate a professional CV for an IT Cyber Engineer with extensive experience "
        "in cybersecurity, network administration, and risk management."
    )

    # Generate and save the cover letter and CV
    cv_gen.generate_cover_letter(cover_letter_prompt, app_folder)
    cv_gen.generate_cv(cv_prompt, app_folder)
