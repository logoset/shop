# # \ -w -p 4000 # указать желаемый порт

require File.expand_path('script.rb', File.dirname(__FILE__))
# require './script.rb' # подгрузить script.rb
run Sinatra::Application # запустить приложение
