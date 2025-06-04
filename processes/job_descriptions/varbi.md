from pathlib import Path

# Skapa innehåll till markdownfilen
markdown_content = """# Ansökan: Systemtekniker GIS – Applikationer och DevOps  
**Myndighet:** Länsstyrelserna  
**Datum:** 2025-06-03  
**Sökande:** Rickard Åberg

---

## 1. Vad gör dig intresserad av det här jobbet?  
Jag har tidigare arbetat som IT Problem Manager för Länsstyrelsen och fick stor respekt för verksamhetens tekniska komplexitet och samhällsnytta. Nu vill jag bidra mer praktiskt med min kompetens inom systemdrift, DevOps och automatisering.

## 2. Vad kan du bidra med i det här jobbet  
Jag har bred erfarenhet inom utveckling, testautomatisering och DevOps. Jag har arbetat med CI/CD, Terraform, Bash/PowerShell, backend i C# och Python, samt databaser som PostgreSQL och SQL Server. Jag har använt deploy- och testverktyg som CA Lisa, Jenkins och Azure DevOps, bland annat i projekt hos Ikano. Jag har god förmåga att felsöka komplexa system och förbättra processer.

## 3. Har du en högskoleutbildning inom IT-området eller motsvarande kompetens?  
✅ Ja – civilingenjör i datateknik

## 4. Har du erfarenhet av teknisk IT-drift (applikationer i servermiljö)?  
✅ Ja

## 5. Beskriv din erfarenhet av teknisk IT-drift  
Jag har driftat applikationer i Linux- och Windowsmiljö, ansvarat för deployment, loggning och övervakning. Som IT Problem Manager för Länsstyrelsen höll jag regelbundet möten kring återkommande problem. På Ikano deltog jag i major incident-möten där vi felsökte och löste driftstörningar i realtid, ofta via chattbaserad kommunikation med utvecklare, drift och supportteam.

## 6. Har du god erfarenhet av att arbeta i en DevOps-miljö med CI/CD?  
✅ Ja

## 7. Beskriv din erfarenhet av DevOps/CI-CD  
Jag har byggt CI/CD-pipelines i Jenkins, GitHub Actions, GitLab CI och Azure DevOps. Jag har använt Terraform, Docker, Kubernetes och Helm för automatiserad deploy och miljöhantering. Jag har även erfarenhet av CA Lisa för automatiserade tester och integrationstester i större systemmiljöer.  
Jag är certifierad i Azure Fundamentals och studerar nu för AZ-500. Jag har skrivit infrastruktur för Azure i både PowerShell och Terraform.

## 8. Har du en stark förmåga att felsöka och debugga system?  
✅ Ja

## 9. Beskriv din förmåga att felsöka/debugga  
Jag felsöker effektivt i distribuerade system med verktyg som `curl`, `tcpdump`, `htop`, `netstat`, `dig`, `nmap` och logganalys. Jag har lett felsökningsmöten som Problem Manager och deltagit i realtidsincidenter på Ikano.  
Mitt intresse för etisk hackning har också gett mig vana att felsöka nätverk och applikationer i Linuxmiljö med kommandoradsverktyg, vilket fördjupat min förståelse för både säkerhet och infrastruktur.

## 10. Markera områden du har erfarenhet av  
- SQL Server, PostgreSQL/PostGIS  
- Python, TypeScript, PowerShell, Bash, C#  
- Linux och Windows Server  
- Drift av Java- och .NET-applikationer  
- Docker och Kubernetes  
- Infrastruktur som kod: Terraform, YAML, Helm  
- Viss erfarenhet av QGIS och GeoServer

## 11. Vilka placeringsorter är du intresserad av?  
- Göteborg  
- Karlstad  
- Annan ort enligt överenskommelse
"""

# Spara filen
file_path = Path("/mnt/data/ansokan-lst-systemtekniker.md")
file_path.write_text(markdown_content, encoding="utf-8")

file_path.name
