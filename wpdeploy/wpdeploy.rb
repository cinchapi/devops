#!/usr/bin/env ruby
# This script will deploy a new Wordpress instance

require 'open-uri'
require 'fileutils'

# Global variables
wordpress_tar_file = "wordpress.tar.gz"
wordpress_home = "~/scratch"

# Shutdown hook
at_exit do
  File.delete(wordpress_tar_file)
end

# Get information from user
print "Wordpress Blog Name: "
name = gets.chomp.downcase.tr(' ', '_')

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
