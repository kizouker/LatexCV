class CVGenerator:
    def __init__(self, openai_api_key, output_dir="Applications"):
        self.openai_api_key = openai_api_key
        openai.api_key = self.openai_api_key
        self.output_dir = output_dir

    def create_file_structure(self, application_date, company, role):
        """Creates a structured folder for the application."""
        folder_name = f"{application_date}_{company.replace(' ', '-')}_{role.replace(' ', '-')}"
        folder_path = os.path.join(self.output_dir, folder_name)
        os.makedirs(folder_path, exist_ok=True)
        print(f"Created folder: {folder_path}")
        return folder_path

    def save_metadata(self, folder_path, metadata):
        """Saves a metadata JSON file in the given folder."""
        metadata_file = os.path.join(folder_path, "metadata.json")
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=4, ensure_ascii=False)
        print(f"Metadata saved to {metadata_file}")

    def generate_text(self, prompt, model="gpt-4"):
        """Wraps an OpenAI API call to generate text based on a prompt."""
        print("Generating text with OpenAI API...")
        response = openai.ChatCompletion.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are an expert CV and cover letter writer."},
                {"role": "user", "content": prompt}
            ]
        )
        generated_text = response.choices[0].message.content.strip()
        print("Text generation complete.")
        return generated_text

    def generate_cover_letter(self, prompt, folder_path):
        """Generates a cover letter using OpenAI and saves it as a file."""
        cover_letter = self.generate_text(prompt)
        file_path = os.path.join(folder_path, "cover_letter.tex")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(cover_letter)
        print(f"Cover letter saved to {file_path}")

    def generate_cv(self, prompt, folder_path):
        """Generates a CV using OpenAI and saves it as a file."""
        cv_text = self.generate_text(prompt)
        file_path = os.path.join(folder_path, "cv.tex")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(cv_text)
        print(f"CV saved to {file_path}")
