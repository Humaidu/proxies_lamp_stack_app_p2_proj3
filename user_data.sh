#!/bin/bash
exec > /var/log/user_data.log 2>&1
set -x  # Optional: trace commands

# Install LAMP stack
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mysqlnd unzip mariadb-server php-mysqlnd

# Start and enable Apache and MariaDB
systemctl start mariadb
systemctl enable mariadb
systemctl start httpd
systemctl enable httpd

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Confirm aws is installed
which aws
aws --version

# Check and log variable values
echo "DB_ENDPOINT: ${db_endpoint}"
echo "DB_USERNAME: ${db_username}"
echo "DB_PASSWORD: ${db_password}"
echo "DB_NAME:     ${db_name}"

# Create environment file
cat > /tmp/.env <<EOL
DB_ENDPOINT=${db_endpoint}
DB_USERNAME=${db_username}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
EOL

# Copy .env file to /var/www/html/
cp /tmp/.env /var/www/html/

echo "Attempting to copy app from S3 to /var/www/html at $(date)" >> /tmp/app_copy.log

# Copy app files from S3
aws s3 cp s3://lamp-stack-app-bucket-0921/php-app/ /var/www/html/ --recursive >> /tmp/app_copy.log 2>&1
aws s3 ls s3://lamp-stack-app-bucket-0921/php-app/

# Set permissions
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod 644 /var/www/html/.env

# Clean up
sudo rm -rf /tmp/php-app /tmp/.env


# CloudWatch Agent Setup Script

# Log start time
echo "Starting CloudWatch Agent setup at $(date)" >> /tmp/cloudwatch_setup.log

# Install CloudWatch Agent
sudo yum update -y
sudo yum install -y amazon-cloudwatch-agent

# Create config file directory
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

# Pre-create app log files to ensure CloudWatch Agent sees them
mkdir -p /var/log
sudo touch /var/log/php-app-visits.log /var/log/php-app-errors.log
sudo chown apache:apache /var/log/php-app-*.log
sudo chmod 644 /var/log/php-app-*.log

# ─────── Warm-up: Force logs to be written ───────
curl -s http://localhost/index.php || echo "PHP app not ready, curl failed."

# Write CloudWatch Agent JSON config
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/lamp-stack-app/apache-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/lamp-stack-app/apache-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/lamp-stack-app/system-messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/php-app-visits.log",
            "log_group_name": "/lamp-stack-app/php-app-visits",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/php-app-errors.log",
            "log_group_name": "/lamp-stack-app/php-app-errors",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "\$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": ["cpu_usage_idle"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Restart CloudWatch Agent properly
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s