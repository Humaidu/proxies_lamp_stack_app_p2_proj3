#!/bin/bash
exec > /var/log/user_data.log 2>&1
set -x  # Optional: trace commands

# Install LAMP stack
yum update -y
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd mysqlnd unzip mariadb-server php-mysqlnd

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

cp /tmp/.env /var/www/html/


# Copy app files from S3
aws s3 cp s3://lamp-stack-app-bucket-0921/php-app/ /var/www/html/ --recursive
aws s3 ls s3://lamp-stack-app-bucket-0921/php-app/

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
chmod 644 /var/www/html/.env

# Clean up
rm -rf /tmp/php-app /tmp/.env