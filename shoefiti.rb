require 'rubygems'
require 'date'
require 'json'

Shoes.app :title => "Shoefiti - Librelist Browser" do
	URL = "http://librelist.com/archives/"
	@listurl = ""
	def getlist
		download(URL+@listurl) do |list|
			@lists = eval(list.response.body)[1]
			@place = eval(list.response.body)[0].split("/")
			debug(@lists)
			debug(@place)
			stack do
				if @place.length < 5 #Need to break out of this once we get to the list of days. Odd array length due to split on /
					list_box :items => @lists do |list|
						@listurl += list.text
						getlist
					end
				else
							#debug("Pop1")
							#debug(@place.pop)
							#debug("Pop2")
							#debug(@place.pop)
							drawcalendar(@place.pop.to_i, @place.pop.to_i, @place.pop.to_s, @lists)	#pass @lists?	
				end	
			end		
		end
	end

	getlist


	def drawcalendar(month, year, list, maildays)
	off=Date.new(year, month, 01).wday-1 #Offset, not sure wh yI need the -1 here, but I do.
	mdays=(Date.new(year, 12, 31) << (12-month)).day #Days in the month
	rows=((mdays+off+1).to_f/7.0).ceil #Number of rows in calendar, plus 1 to compensate for -1 above. Have confused myself
		days = %w{Su Mo Tu We Th Fr Sa}
		days.each do |column|
			i = days.index(column)
			row = 0
			stack :left => i*50, :top => 100 do
				para column
				until row == rows do
					calday = i-off+7*row
					if (1..mdays) === calday #Only want to draw if greater than zero and less than max days
						if calday.to_s.length == 1
							caldaystr = "0"+calday.to_s
						else
							caldaystr = calday.to_s
						end
						if maildays.include?(caldaystr+"/") #deal with "0" in front of single digits
							para make_date_link(list, year, month, calday)
						else
							para calday
						end
					else 
						para ""
					end#
					row += 1
				end
			end
		end
	end

	def make_date_link(list, year, month, day) #http://thread.gmane.org/gmane.comp.lib.shoes/4042/focus=4044
		link(day){getmails(list, year, month, day)}
	end
	
	def getmails(list, year, month, day)
		#need to fix months and days here, ie 0 on front.
		if month.to_s.length == 1
			month = "0"+month.to_s
		else
			month = month.to_s
		end
		if day.to_s.length == 1
			day = "0"+day.to_s
		else
			day = day.to_s
		end
		url = "http://librelist.com/archives/"+list+"/"+year.to_s+"/"+month.to_s+"/"+day.to_s+"/json/"
		debug(url)
		download(url) do |data|
			emails = eval(data.response.body)[1]
			debug(emails.length)
			emails.each do |message|
				download(url+message) do |data|
					js = JSON.parse(data.response.body)
					stack :margin => 10, :width => 400 do
							border black, :strokewidth => 3, :curve => 5 
							inscription js["headers"]["Date"]
							inscription js["headers"]["From"]
							inscription js["headers"]["Subject"]
					end
						#para js["body"] #Need to sanatize this a bit for output
				end
			end
				# Where to store all these? Or just draw straight away?
		end
	end
		

end
