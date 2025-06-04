#fetch_to_md.sh


#!/bin/bash

# Konstant: din URL
readonly JOB_URL="https://www.linkedin.com/jobs/view/4235205242/?alternateChannel=search&refId=ueMVt8n0v1x7511vzbucvw%3D%3D&trackingId=NboF1JmI4k4M7YDegfPu4g%3D%3D&trk=d_flagship3_company_posts"

# Filnamn att spara till
OUTFILE="./linkedin_job.md"

# Hämta sidan, strippa HTML och spara till .md
curl -s "$JOB_URL" | lynx -dump -stdin | sed '/^References$/q' > "$OUTFILE"

echo "✅ Sparat som $OUTFILE"
