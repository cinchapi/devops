#!/usr/bin/env ruby
# This script will deploy a new Wordpress instance

require 'open-uri'
require 'fileutils'
require 'linode'
require 'mysql'

# Configuration variables
domain = "YOUR DOMAIN HERE"
linode_api_key = "YOUR API KEY HERE"
ip_address = "YOUR IP ADDRESS HERE"

# Global variables
wordpress_tar_file = "wordpress.tar.gz"
wordpress_home = "/var/www/html"
$chars = [('a'..'z'), ('A'..'Z'), ('1'..'9')].map { |i| i.to_a }.flatten
apache_conf = "/etc/httpd/conf/httpd.conf"

# Global functions
def generate_string(size)
  (0...size).map { $chars[rand($chars.length)] }.join
end

# Find the @search test in @file and switch it with the
# @replace text
def find_and_replace(search, replace, file)
  f = File.open(file, 'r')
  content = f.read
  f.close
  content.gsub!(search, replace)
  File.open(file, 'w'){ |s| s << content }
end

# Shutdown hook
at_exit do
  File.delete(wordpress_tar_file)
end

# Get information from user
print "Wordpress Blog Name: "
name = gets.chomp.downcase.tr(' ', '_')

print "Your MySQL username: "
my_admin_user = gets.chomp

print "Your MySQL password: "
my_admin_pass = gets.chomp

# Download wordpress
File.open(wordpress_tar_file, 'wb') do |file|
  file.write open("https://wordpress.org/latest.tar.gz").read
end

# Extract wordpress
tar_gz_archive = wordpress_tar_file
wordpress_home << "/" unless wordpress_home.end_with?("/")
destination = File.expand_path(File.join wordpress_home, name)
FileUtils::mkdir_p destination
system "tar xvfz #{tar_gz_archive} --strip-components=1  -C #{destination}"
puts "Installed wordpress in #{destination}"

# Setup MySQL
my_user = generate_string 10
my_pass = generate_string 15
begin
  con = Mysql.new 'localhost', my_admin_user, my_admin_pass
  con.query "CREATE DATABASE #{my_user}"
  con.query "CREATE USER '#{my_user}'@'localhost' identified by '#{my_pass}''"
  con.query "GRANT ALL PRIVILEGES ON `#{my_user}` . * TO '#{my_user}'@'localhost'"
  con.query "FLUSH PRIVILEGES"
rescue Mysql::Error => e
  puts e.errno
  puts e.error
ensure
  con.close if con
end

# Setup wordpress
wp_config = File.join destination, "wp-config.php"
FileUtils.cp(File.join(destination, "wp-config-sample.php"), wp_config)
find_and_replace "database_name_here", my_user, wp_config
find_and_replace "username_here", my_user, wp_config
find_and_replace "password_here", my_pass, wp_config

# Configure domain
url = name.tr('_', '-')
linode = Linode.new(:api_key => linode_api_key)
domain_id = "-1"
linode.domain.list.each { |x| domain_id = x.domainid if x.domain == domain }
linode.domain.resource.create(:DomainID => domain_id, :Type => "A", :Name => url, :Target => ip_address, :TTL_sec => 300) unless domain_id == "-1"

# Add virtual host to apache conf
apache_conf = File.expand_path(apache_conf)
File.open(apache_conf, 'a') do |f|
  f.puts "<VirtualHost *:80>"
  f.puts "  DocumentRoot #{destination}"
  f.puts "  ServerName #{url}.#{domain}"
  f.puts "  ServerAlias #{url}.#{domain}"
  f.puts "</VirtualHost>"
end

# Restart Apache
system 'sudo service httpd restart'
