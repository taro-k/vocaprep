# encoding: utf-8

require 'rubygems'
require 'json'
require 'sqlite3'

require './subscript.rb'

# Set your level from 0.0 to 10.0 as the most difficult.
levelYou = 0.0

# Interval between web API call is 3 sec. by default. Please respect API
# provider, and too many requests in shor time may make your IP banned.
sleepAPI = 3

# Setup DB to store global dictionary
dictGlobalFile = "db/dictGlobal.db"
tmpBool = File.exists?(dictGlobalFile)
dictGlobal = SQLite3::Database.new(dictGlobalFile)
# Initialize if DB doesn't exist.
if !tmpBool
sql = <<SQL
create table words (
  word varchar(255),
  level float,
  sensejp varchar(255)
);
SQL
dictGlobal.execute(sql)
p "Initialized DB:"+dictGlobalFile
end

# Open test input file.
inputDoc = File.open("test.txt")

# Declare an array to put words.
inputWords = Array.new

# For each line of the document, pick up words which are more than
# 4 characters of a-z and A-Z.
# At this moment, the code regards ' as just separater.
inputDoc.each do |inputLine|
  inputWords << inputLine.scan(/[a-zA-Z]{4,}/)
  #inputWords << inputLine.scan(/[a-zA-Z'’]{4,}/)
end
inputDoc.close

# Flatten the nested array and make it unique.
inputWords.flatten!
inputWords.uniq!

# For each word in input document
inputWords.each do |inputWord|
  ##p inputWord
  # If the word is already in DB
  rowWord = dictGlobal.execute('select * from words where word=?',inputWord)
  if rowWord.length > 0
    # output the DB record if the word level is >= your level.
	rowWordLevel = rowWord[0][1]
    if rowWordLevel >= levelYou
    ##if (rowWordLevel >= levelYou)||(rowWordLevel == 0.0)
      p rowWord
	end
  # If not,
  else
    # access to API, which returns JSON format.
    urlbaseApi="http://ivoca.31tools.com/api/wordlevel?word="
    responseHttp = fetch(urlbaseApi+inputWord)
	# Transform JSONs to array of hash.
    responseHash = JSON.parse(responseHttp.body)

    # If API dictionary hits the result
    if responseHash.length != 0
      # Sort the result in descending order of reliability
      responseHash.sort! do |a, b|
        b["reliability"] <=> a["reliability"]
      end
      ##p responseJson[0]["reliability"]
      # Pickup level and meaning in JP of the word.
      level = responseHash[0]["level"]
      senseJp = responseHash[0]["sense"]
    # If API dictionary miss the result
    else
      level = 0.0
      senseJp = "N/A"
    end

    # Record the result of the word to global dictonary DB, and print it.
    sql = "insert into words values (:word, :level, :sensejp)"
	dictGlobal.execute(sql,:word=>inputWord,:level=>level,:sensejp=>senseJp)
    p inputWord+" "+level.to_s+" "+senseJp

    # Wait for 5 sec. until the next API request.
    sleep(sleepAPI)
  end
end

dictGlobal.close
exit
