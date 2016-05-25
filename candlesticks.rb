#!/usr/bin/env ruby

# https://trading.scottrade.com/quotesresearch/ScottradeResearch.aspx?page=%2fqnr%2fInvestorTools%2fStockScreener
# http://ichart.finance.yahoo.com/table.csv?s="  + @datainput.to_s + "&d=" + cur_month + "&e=" + cur_day +'&f=' + cur_year +"&g=d&a=0&b=01&c=2000&ignore=.csv"
# http://finance.yahoo.com/echarts?s=ADK+Interactive#{"showArea":false,"showLine":false,"showCandle":true,"showBollinger":true,"mfiLineWidth":"4","showMacd":true,"macdSlowPeriod":52,"macdFastPeriod":24,"showStoch":true,"lineType":"candle","range":"3mo","allowChartStacking":true}


require 'net/http'
require 'open-uri'
require 'sqlite3'


#################### SETTING THE STAGE ################################
counter = 0

#tickers = File.read("tickers_bak.dat").split("\n")
tickers = File.read("tickers.dat").split("\n")
puts tickers.length.to_s + " stocks to process."

@yosen_list = []
@morning_star_list = []
@enfungling_bullish_list = []
@piercing_pattern_list = []
@inverted_hammer_list = []
@dead_stocks_list = []
@inverted_hammer_list_cur_price = []


#------------------ QUERYING YAHOO FINANCE FOR TICKET INFO --------------------#

def get_ticker_info(ticker)

  cur_month = (Date.today.strftime("%m").to_i - 1).to_s
  cur_day = Date.today.strftime("%d").to_s
  cur_year = Date.today.strftime("%Y").to_s

  @page_url = "http://ichart.finance.yahoo.com/table.csv?s="  + @datainput.to_s + "&d=" + cur_month + "&e=" + cur_day +'&f=' + cur_year +"&g=d&a=0&b=01&c=2016&ignore=.csv"
  #puts @page_url
  url = URI.parse(@page_url)
  req = Net::HTTP::Get.new(url.to_s)
  res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
  stock_data = res.body.split("\n")
  #puts stock_data
  return stock_data
  

end


def get_current_real_time_price(ticker)
  
  # this function queries money.cnn.com an gets the current stock price at the time of analysis.

  @page_url_real_time = "http://money.cnn.com/quote/quote.html?symb=" + @datainput.to_s
  begin


    url_real = URI.parse(@page_url_real_time)
    req_real = Net::HTTP::Get.new(url_real.to_s)
    res_real = Net::HTTP.start(url_real.host, url_real.port) {|http| http.request(req_real)}
    real_time_stock_price = res_real.body
    raw_results = /t="ToHundredth"\sstreamFeed="SunGard">([\d\.]+)/.match(real_time_stock_price)
    results = raw_results.to_s.gsub('t="ToHundredth" streamFeed="SunGard">','')



    return results

  rescue Exception => ex
    @error_msg = "An error of type #{ex.class} happened, message is #{ex.message}"
    puts @error_msg
  end
  
end

def insert_ticker_data_in_db(xxx)
  id = 0
  for string in xxx
    string = string.split(",")

    date = string[0]
    open = string[1]
    high = string[2]
    low = string[3]
    close = string[4]
    volume = string[5]
    adjustedclose = string[6]
    $db.execute( "INSERT INTO Stocks ( Id, Date, Open, High, Low, Close, Volume, Adjustedclose ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )", [id, date, open, high, low, close, volume, adjustedclose])  
    id += 1
  end

end  

def get_latest_data_from_db

    latest_data_ary = $db.execute "SELECT * FROM Stocks WHERE Id=1"
    #puts latest_data_ary
    #puts "\n"*3
    latest_data_ary.each do |row|
      
      @current_price = row[2].to_f #close
      @current_open = row[3].to_f #open
      @current_low = row[4].to_f #low
      @current_high = row[5].to_f #high
      @current_volume = row[6].to_f #volume
      #puts @current_price, @current_open, @current_low, @current_high
      return [@current_price, @current_open, @current_low, @current_high, @current_volume]

    end

end

def get_previous_data_from_db

    previous_day_data_ary = $db.execute "SELECT * FROM Stocks WHERE Id=2"
    #puts latest_data_ary
    #puts "\n"*3
    previous_day_data_ary.each do |row|
      
      @previous_day_close = row[2].to_f #close
      @previous_day_open = row[3].to_f #open
      @previous_day_low = row[4].to_f #low
      @previous_day_high = row[5].to_f #high
      #puts @current_price, @current_open, @current_low, @current_high
      return [@previous_day_close, @previous_day_open, @previous_day_low, @previous_day_high]

    end

end

def get_2_days_ago_data_from_db

    two_days_ago_data_ary = $db.execute "SELECT * FROM Stocks WHERE Id=3"
    #puts latest_data_ary
    #puts "\n"*3
    two_days_ago_data_ary.each do |row|
      
      @two_days_ago_close = row[2].to_f #close
      @two_days_ago_open = row[3].to_f #open
      @two_days_ago_low = row[4].to_f #low
      @two_days_ago_high = row[5].to_f #high
      #puts @current_price, @current_open, @current_low, @current_high
      return [@two_days_ago_close, @two_days_ago_open, @two_days_ago_low, @two_days_ago_high]

    end

end

def get_3_days_ago_data_from_db

    three_days_ago_data_ary = $db.execute "SELECT * FROM Stocks WHERE Id=4"
    #puts latest_data_ary
    #puts "\n"*3
    three_days_ago_data_ary.each do |row|
      
      @three_days_ago_close = row[2].to_f #close
      @three_days_ago_open = row[3].to_f #open
      @three_days_ago_low = row[4].to_f #low
      @three_days_ago_high = row[5].to_f #high
      #puts @current_price, @current_open, @current_low, @current_high
      return [@three_days_ago_close, @three_days_ago_open, @three_days_ago_low, @three_days_ago_high]

    end

end
#----------------- IDENTIFYING YOSEN CANDLE ---------#

def yosen (open, high, low, close, ticker)

# open price is close or equals to low price
# close price is very close or equal to high price

  full_range = high.to_f - low.to_f 
  bracket = full_range * 0.1
  #puts "Bracket: #{bracket.round(2)}"


  if (open.to_f - low.to_f <= bracket && high.to_f - close.to_f <= bracket) && bracket > 0.01 && close
    #puts open, high, low, close, bracket
    puts "YO-SEN FOUND!!!! ---> #{ticker}" 
    #puts "Full range during the day: " + full_range.round(2).to_s
    #system('say "Yosen found"')
    @yosen_list << ticker
  end
end


def inverted_hammer (three_day_close, open, high, low, close, volume, ticker)
# check if the trend was going down when this pattern occured (three_day_close is bigger than close)

  full_range = high.to_f - low.to_f
  real_body = close.to_f - open.to_f
  upper_shadow = high.to_f - close.to_f


  if open.to_f == low.to_f && close.to_f > open.to_f && upper_shadow > real_body * 2 && three_day_close > close
    newv = (ticker + ' ' + close.to_s + ' ' + volume.to_s).split(",")
    puts "INVERTED HAMMER FOUND!!!", newv #close.to_s
    
    @inverted_hammer_list << newv
  end
end

def enfungling_bullish_model (three_day_close, two_day_close, prev_open, prev_close, prev_low, curr_open, curr_close, curr_low, ticker)

# previous day open is higher than previous day close
# current day open is lower than previous day close and current day close is higher than previous day open

  if three_day_close > two_day_close && two_day_close > prev_close && prev_open > prev_close && curr_open < prev_close && curr_close > prev_open && curr_low < prev_low
    puts "ENFUNGLING BULLISH MODEL FOUND! ---> #{ticker} #{curr_close}" 
    #puts prev_open, prev_close
    #puts curr_open, curr_close
    @enfungling_bullish_list << ticker
  end

end

def piercing_pattern (three_day_close, two_day_close, prev_low, prev_open, prev_close, curr_open, curr_close, ticker)
  
  prev_mid = ((prev_open - prev_close) / 2) + prev_close 

  if prev_close < prev_open && three_day_close > two_day_close && two_day_close > prev_close && curr_open < prev_low && curr_close > prev_mid
      puts "PIERCING PATTERN ---> #{ticker} #{curr_close}"
      @piercing_pattern_list << ticker

  end
end

def morning_star (three_day_close, two_day_close, two_day_open, prev_open, prev_close, curr_open, curr_close, ticker)
  # The pattern is made up of three candles: normally a long bearish candle,
  # a short bullish or bearish doji
  # a long bullish candle. The top of the third candle should be at least halfway up the body of the first candle. 
  if three_day_close > two_day_close && two_day_close > prev_close && two_day_open > two_day_close && prev_open < prev_close && curr_open < curr_close && prev_close < two_day_close && prev_close < curr_open
    puts "MORNING STAR FOUND -----> #{ticker} #{curr_close}"
    @morning_star_list << ticker
  end

end  


def check_if_stock_is_not_popular (three_day_close, two_day_close, prev_close, curr_close, ticker)

  if three_day_close == two_day_close && prev_close == curr_close && two_day_close == prev_close
    @dead_stocks_list << ticker
  end

end


def calculate_revenue(current_stock_price, predicted_price)

  starting_money = 1000
  buying_with = starting_money - 7
  num_shares = buying_with % current_stock_price
  return num_shares

end

####################### EXECUTION ############################
for @datainput in tickers
  counter += 1

  #puts counter
  $db = SQLite3::Database.open "stocks.db"
  #$db.execute "BEGIN TRANSACTION; END;"
  $db.execute "DROP TABLE IF EXISTS Stocks"
  $db.execute "CREATE TABLE Stocks(Id INT, Date TEXT, Open INT, High INT, Low INT, Close INT, Volume INTEGER, Adjustedclose INT)"  
  begin
    puts "\nProcessing stock: " + @datainput.to_s
    real_time_body = get_current_real_time_price(@datainput)
    stock_data = get_ticker_info(@datainput) #query yahoo and retrieve the data
    insert_ticker_data_in_db(stock_data) #save the data in the db

    cur_open = get_latest_data_from_db[0].to_f # most recent data (previous day - latest data available - yesterday's)
    cur_high = get_latest_data_from_db[1].to_f
    cur_low = get_latest_data_from_db[2].to_f
    cur_close = get_latest_data_from_db[3].to_f
    cur_vol = get_latest_data_from_db[4].to_f

    prev_open = get_previous_data_from_db[0].to_f # a day before yesterday
    prev_high = get_previous_data_from_db[1].to_f
    prev_low = get_previous_data_from_db[2].to_f
    prev_close = get_previous_data_from_db[3].to_f

    two_days_ago_open = get_2_days_ago_data_from_db[0].to_f # two days ago
    two_days_ago_high = get_2_days_ago_data_from_db[1].to_f
    two_days_ago_low = get_2_days_ago_data_from_db[2].to_f
    two_days_ago_close = get_2_days_ago_data_from_db[3].to_f

    three_days_ago_open = get_3_days_ago_data_from_db[0].to_f # three days ago
    three_days_ago_high = get_3_days_ago_data_from_db[1].to_f
    three_days_ago_low = get_3_days_ago_data_from_db[2].to_f
    three_days_ago_close = get_3_days_ago_data_from_db[3].to_f

    '''
    puts @page_url
    puts "\nCurrent open: " + cur_open.to_s
    puts "Current high: " + cur_high.to_s
    puts "Current low: " + cur_low.to_s
    puts "Current close: " + cur_close.to_s

    puts "\nPrev open: " + prev_open.to_s
    puts "Prev high: " + prev_high.to_s
    puts "Prev low: " + prev_low.to_s
    puts "Prev close: " + prev_close.to_s

    puts "\n2 days ago open: " + two_days_ago_open.to_s
    puts "2 days ago high: " + two_days_ago_high.to_s
    puts "2 days ago low: " + two_days_ago_low.to_s
    puts "2 days ago close: " + two_days_ago_close.to_s

    puts "\n3 days ago open: " + three_days_ago_open.to_s
    puts "3 days ago high: " + three_days_ago_high.to_s
    puts "3 days ago low: " + three_days_ago_low.to_s
    puts "3 days ago close: " + three_days_ago_close.to_s
    '''
    #print cur_open, " ", cur_high, " ", cur_low, " ", cur_close
    #puts "\n"
    #print prev_open, " ", prev_high, " ", prev_low, " ", prev_close
    #puts "\n"
    #puts three_days_ago_close, two_days_ago_close, prev_close, cur_close
    
    yosen(cur_open, cur_high, cur_low, cur_close, @datainput)
    inverted_hammer(three_days_ago_close, cur_open, cur_high, cur_low, cur_close, cur_vol, @datainput)
    enfungling_bullish_model(three_days_ago_close, two_days_ago_close, prev_open, prev_close, prev_low, cur_open, cur_close, cur_low, @datainput)
    piercing_pattern(three_days_ago_close, two_days_ago_close, prev_low, prev_open, prev_close, cur_open, cur_close, @datainput)
    morning_star(three_days_ago_close, two_days_ago_close, two_days_ago_open, prev_open, prev_close, cur_open, cur_close, @datainput)
    
    puts "Current_stock_price is: " + real_time_body.to_s
    puts "Current volume: " + cur_vol.to_s

  rescue Exception => ex
    @error_msg = "An error of type #{ex.class} happened, message is #{ex.message}"
    puts @error_msg

  end
  
end

puts "All Done"
puts "Yo Sen found: " + @yosen_list.join(",")
puts "Inverted hammers found: " + @inverted_hammer_list.join(",")
puts "Morning Stars found: " + @morning_star_list.join(",")
puts "Enfungling found: " + @enfungling_bullish_list.join(",")
puts "Piercing Patterns found: " + @piercing_pattern_list.join(",")
puts "Stocks to exclude from further analysis: " + @dead_stocks_list.join(",")
