#!/bin/bash

# Check if Docker is installed, install if not
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed, install if not
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi
cat > $HOME/prometheus/prometheus.yml <<EOF
global:
  scrape_interval : 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

echo "✅ prometheus.yml created at /home/prometheus_grafana"
# Check if Prometheus container is already running, run if not
if ! docker ps --filter "name=prometheus" | grep "prometheus" > /dev/null; then
    echo "Starting Prometheus container..."
    docker run -d --name=prometheus -p 9090:9090 -v $HOME/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
else
    echo "Prometheus container is already running."
fi

# Check if Grafana container is already running, run if not
if ! docker ps --filter "name=grafana" | grep "grafana" > /dev/null; then
    echo "Starting Grafana container..."
    docker run -d --name=grafana -p 3000:3000 grafana/grafana
else
    echo "Grafana container is already running."
fi

echo "Setup completed!"
