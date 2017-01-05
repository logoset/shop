# # \ -w -p 4000 # указать желаемый порт для локального запуска на порту 4000, надо убрать первую решетку и пробел, для деплоя в heroku, опять закомментировать

require File.expand_path('script.rb', File.dirname(__FILE__))
# require './script.rb' # подгрузить script.rb
run Sinatra::Application # запустить приложение
