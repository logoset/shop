#web: bundle exec thin start -p $PORT
#web: bundle exec rackup config.ru -p $PORT
#web: bundle exec thin start -R config.ru -e $RACK_ENV -p $PORT
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
#web: bundle exec puma -C config/puma.rb
#rake: bundle exec rake
#console: bundle exec irb
