#!/bin/bash
# webappdocker.sh

set -e  # Exit on any error

# Update and install Docker and dependencies
sudo apt update && sudo apt install -y docker.io wget apt-transport-https gnupg lsb-release

# Start Docker service
sudo service docker start

# Create working directory
mkdir -p vuln-webapp && cd vuln-webapp

# Create a basic Flask app
cat > app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from vulnerable app!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
EOF

# Requirements file
echo "Flask==2.2.5" > requirements.txt
echo "Jinja2==3.1.2" >> requirements.txt

# Dockerfile for the app
cat > Dockerfile <<EOF
FROM python:3.8-slim
WORKDIR /app
COPY requirements.txt . 
RUN pip install -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
EOF

# Build and run the Docker container
docker build -t vuln-app .
docker run -d --name vuln-app -p 5000:5000 vuln-app

# Output app URL
echo "✅ App is running at: http://localhost:5000"

# Install Trivy securely (no deprecated apt-key)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb jammy main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null

sudo apt update && sudo apt install -y trivy

# Run vulnerability scan (app remains running)
echo "🔎 Running Trivy scan on Docker image vuln-app..."
trivy image vuln-app
