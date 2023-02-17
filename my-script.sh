#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "This page is created by TERRAFORM" | sudo tee /var/www/html/index.html
