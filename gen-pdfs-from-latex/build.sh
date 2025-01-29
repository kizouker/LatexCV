
bash ./cleanUp.sh
echo "building latex and pdf"
#latexmk -silent -f --outdir=./build -pdf ./*.tex
#latexmk  -pvc -f --outdir=./build -pdf ./*.tex
latexmk  -f --outdir=./build -pdf ./*.tex 

# -bibtex ./CV-bibb.bbl