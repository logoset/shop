# #\ -p 7000
require 'rubygems'
require 'bundler'
Bundler.require

require './script.rb'
run Sinatra::Application
