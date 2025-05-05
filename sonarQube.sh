#!/bin/bash

set -e

# STEP 1: START SONARQUBE
# echo "🚀 Starting SonarQube using Docker..."
# docker run -d --name sonarqube -p 9000:9000 sonarqube:community

# echo "⌛ Waiting for SonarQube to initialize (60s)..."
# sleep 60  # Give SonarQube time to initialize fully

# STEP 2: INSTALL REQUIRED TOOLS
echo "📦 Installing unzip and Java if not present..."
sudo apt update
sudo apt install -y unzip default-jdk

# STEP 3: INSTALL & SETUP SONAR-SCANNER
WORKDIR="$HOME/sonar-setup"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "📦 Downloading SonarScanner..."
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip

SCANNER_DIR=$(find "$WORKDIR" -type d -name "sonar-scanner-*")
export PATH="$SCANNER_DIR/bin:$PATH"

# Optional: persist path in .bashrc
if ! grep -q "$SCANNER_DIR/bin" ~/.bashrc; then
  echo "export PATH=\"$SCANNER_DIR/bin:\$PATH\"" >> ~/.bashrc
fi

# STEP 4: VERIFY INSTALLATION
if ! command -v sonar-scanner &> /dev/null; then
    echo "❌ sonar-scanner command not found in PATH"
    exit 1
fi

# STEP 5: SETUP SAMPLE PYTHON CODE FOR ANALYSIS
PROJECT_DIR="$HOME/experimet_script"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📁 Creating sample Python code..."
cat <<EOF > app.py
def greet(name):
    print(f"Hello, {name}!")

greet("SonarQube")
EOF

echo "📦 Writing requirements.txt..."
cat <<EOF > requirements.txt
Flask==2.2.5
Jinja2==3.1.2
EOF

# STEP 6: CREATE sonar-project.properties
echo "📝 Creating sonar-project.properties..."
cat <<EOF > sonar-project.properties
sonar.projectKey=Test
sonar.projectName=test
sonar.projectVersion=1.0

sonar.sources=.
sonar.language=py
sonar.sourceEncoding=UTF-8
sonar.exclusions=**/venv/**,**/__pycache__/**

sonar.host.url=http://localhost:9000
sonar.login=sqp_a26550783cc751617fd7cbba94414cad931e5f7a
EOF

# STEP 7: RUN ANALYSIS
echo "🔍 Running SonarScanner..."
sonar-scanner

echo "✅ Done! View results at: http://localhost:9000"
