#!/bin/bash
# Basic setup script for GCP Compute Engine instance

# Update system
apt-get update -y

# Install basic packages
apt-get install -y htop curl wget

# Install and start Apache
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2

# Create a simple index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Basic GCP Compute Example</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 40px; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Basic GCP Compute Example</h1>
            <p>Deployed with Brockhoff Cloud Terraform Modules</p>
        </div>
        
        <div class="info">
            <h3>Instance Information</h3>
            <p><strong>Name Prefix:</strong> ${name_prefix}</p>
            <p><strong>Instance Name:</strong> <span id="instance-name">Loading...</span></p>
            <p><strong>Zone:</strong> <span id="zone">Loading...</span></p>
            <p><strong>Machine Type:</strong> <span id="machine-type">Loading...</span></p>
        </div>
    </div>
    
    <script>
        // Fetch instance metadata
        fetch('http://metadata.google.internal/computeMetadata/v1/instance/name', {
            headers: {'Metadata-Flavor': 'Google'}
        })
            .then(response => response.text())
            .then(data => document.getElementById('instance-name').textContent = data)
            .catch(error => document.getElementById('instance-name').textContent = 'Unable to fetch');
            
        fetch('http://metadata.google.internal/computeMetadata/v1/instance/zone', {
            headers: {'Metadata-Flavor': 'Google'}
        })
            .then(response => response.text())
            .then(data => document.getElementById('zone').textContent = data.split('/').pop())
            .catch(error => document.getElementById('zone').textContent = 'Unable to fetch');
            
        fetch('http://metadata.google.internal/computeMetadata/v1/instance/machine-type', {
            headers: {'Metadata-Flavor': 'Google'}
        })
            .then(response => response.text())
            .then(data => document.getElementById('machine-type').textContent = data.split('/').pop())
            .catch(error => document.getElementById('machine-type').textContent = 'Unable to fetch');
    </script>
</body>
</html>
EOF

# Set proper permissions
chown www-data:www-data /var/www/html/index.html
chmod 644 /var/www/html/index.html

# Log completion
echo "Setup completed at $(date)" >> /var/log/startup-script.log