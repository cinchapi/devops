# Wordpress Deploy
This script automates the process of deploying a wordpress instance to a linode web server with Apache. In addition to installing wordpress, the script will register a domain for the blog and configure Apache to server it.

## Installation
```bash
gem install linode
gem install mysql
```

## Usage
```bash
sudo su -
$ ./wpdeploy.rb
Wordpress Blog Name: Test Blog
Your MySQL username: jdoe
Your MySQL password:
```

