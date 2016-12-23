# encoding: UTF-8

# gem install thin
# gem install sinatra
# gem install sinatra-contrib
# gem install json

Encoding.default_external=Encoding::UTF_8
Encoding.default_internal=nil

require 'sinatra'
require 'json'
require "sinatra/reloader" if development?

configure do
  set :port, 7000
  enable :sessions
  set :environment, :development
  # set :environment, :production
  enable :logging
  set :server, %w[webrick thin mongrel]
  # disable :run
end

before do
  unless  File.file?("#{Dir.pwd}/db.json")
    @db=[{"id"=>rand(10000000000000000),"category"=>{"category_id"=>1,"name"=>"растения"},"name"=>"elka","description"=>"какой-то текст","price"=>234,"count"=>60,"image"=>"elka.png"},{"id"=>rand(10000000000000000),"category"=>{"category_id"=>2,"name"=>"электроника"},"name"=>"smartfon","description"=>"двухсимочный","price"=>60234,"count"=>59,"image"=>""},{"id"=>rand(10000000000000000),"category"=>{"category_id"=>3,"name"=>"бытовая техника"},"name"=>"utug","description"=>"home product","price"=>3234,"count"=>79,"image"=>""}]
  end
  @db||= JSON.parse(File.open("#{Dir.pwd}/db.json",'r:UTF-8',&:read))
  @products=@db
  @currency="₽"
end

after do
  File.open("#{Dir.pwd}/db.json",'w:UTF-8') {|f| f.write(JSON.pretty_generate(@db))}
end

get "/" do
  @title=@content_header="Список товаров"
  erb :index
end

get "/category/:id" do
  @products=@db.select {|elem| elem['category']['category_id'] == params[:id].to_i} unless params[:id].nil?
  @title=@content_header="Товары из раздела: #{@products[0]['category']['name'] unless @products.empty? }"
  erb :index
end

get '/elem/:id' do
  @products=@db.select {|elem| params[:id]==elem['id'].to_s} unless params[:id].nil?
    @title=@content_header="Информация о товаре"
  erb :info
end

get '/login' do
  @title=@content_header="Авторизация"
  redirect "/" if session['logged']
  erb :login
end

post "/login" do
  unless session['logged'].nil?
    redirect "/"
  end
  @users||= JSON.parse(File.open("#{Dir.pwd}/users.json",'r:UTF-8',&:read))
  user=@users.select {|elem| params[:user]==elem['login'] && params[:passw]==elem['password']} unless params[:user].nil? && params[:passw].nil?
  unless user.empty?
    session['logged']=Hash.new
    session['logged']['user'] = params[:user]
    redirect "/"
  else
    @msg="Такого пользователя не существует!"
    @title="Ошибка авторизации"
    @link='/login'
    erb :msg
  end
end

get '/logout' do
  redirect "/" unless session['logged']
  session['logged'].delete('basket')
  session.delete('logged')
  session.clear
  redirect "/"
end

get "/basket" do
  redirect "/login" unless session['logged']
  @title=@content_header="Корзина выбранных для покупки товаров"
  erb :basket
end

get "/basket/:id" do
  redirect "/login" unless session['logged']
  if session['logged']['basket'].nil?
    session['logged']['basket'] = {}
  end
  if session['logged']['basket'].has_key?(params[:id])
    if session['logged']['basket'][params[:id]] < @db.select {|elem| params[:id]==elem['id'].to_s}[0]['count']
        session['logged']['basket'][params[:id]]+=1
        redirect request.referrer||"/"
    else
      @msg="Этот товар добавить в корзину нельзя, иначе товар в корзине превысит его количество на складе!"
      @title="Ошибка добавления в корзиину"
      @link=request.referrer||"/"
      erb :msg
    end
  else
    if @db.select {|elem| params[:id]==elem['id'].to_s}[0]['count'] > 0
      session['logged']['basket'][params[:id]]=1
      redirect request.referrer||"/"
    else
      @msg="Этот товар добавить в корзину нельзя, т.к. его нет в наличии<br>количество = 0"
      @title="Ошибка добавления в корзиину"
      @link=request.referrer||"/"
      erb :msg
    end
  end
end

get '/purchase' do
  redirect "/login" unless session['logged']
  if session['logged']['basket']
    File.file?("#{Dir.pwd}/purchases.json")? @purchases||= JSON.parse(File.open("#{Dir.pwd}/purchases.json",'r:UTF-8',&:read)) :  @purchases||=[]
    File.file?("#{Dir.pwd}/users.json")? @users||= JSON.parse(File.open("#{Dir.pwd}/users.json",'r:UTF-8',&:read)) :  @users||=[]
    i=0
    time=Time.now.to_i
    while i <= @db.length-1
      session['logged']['basket'].each do |key,value|
        if @db[i]['id'].to_s == key.to_s && @db[i]['count']-value >= 0
          @db[i]['count']-=value
          # есть нюанс, что в базе, пользоаптелей с одинаковым именем может быть несколько, тогда нужно в сессиях хранить еще и user_id
          # данная выборка из массива пользователей  исходит из того, что логин уникален в базе
          user=@users.select {|elem| elem['login'] == session['logged']['user']}[0]
          @purchases.push(
            {
              "id"=>rand(10000000000000000),
              "invoice"=>"#{rand(10000)}-#{rand(10000)}-#{rand(10000)}-#{rand(10000)}",
              "product_id"=>key.to_i,
              "count"=>value,"datetime"=>time,
              "datetimevisble"=>Time.at(time),
              "cookie_session_id"=>session['session_id'],
              "payinfo"=>"","user"=>session['logged']['user'],
              "user_id"=>user['id'],
              "contact"=>{
                  "email"=>!user.empty??user['contact']['email']:"",
                  "phone"=>!user.empty??user['contact']['phone']:"",
                  "address"=>!user.empty??user['contact']['address']:""
              }
            }
          )
        end
      end
      i+=1
    end
    session['logged']['basket'] = nil
    session['logged'].delete('basket')
  end
  File.open("#{Dir.pwd}/purchases.json",'w:UTF-8') {|f| f.write(JSON.pretty_generate(@purchases))} unless @purchases.nil?
  @msg="Товар куплен!<br> Спасибо за покупку!<br>Товар будет отправлен по указанному адресу доставки..."
  @link=request.referer||"/"
  erb :msg
end

get '/trash' do
  if session['logged']
    session['logged']['basket'] = nil
    session['logged'].delete('basket')
  redirect request.referer||"/"
  end
end

get "/env" do
  require 'json'
  content_type :text
  return JSON.pretty_generate(request.env)
end

__END__

@@ msg
<table width='100%' height='100%'>
  <tr align='center'>
    <td align='center'><%= @msg %><br><a href='<%= @link %>'>назад</a></td>
  </tr>
</table>


