require 'rubygems'
require 'date'
require 'json'

Shoes.app :title => "Shoefiti - Librelist Browser", :height => 700, :scroll => false do
	
	URL = "http://librelist.com/archives/"

	#Try doing single list box owing to list_box troubles on shoes MinGW
	#More closely mimics the web interface
	@stack_list = stack :margin => 10 do
		
		@list_list = list_box do |list| 
			@list = list.text	
			download(URL+@list) do |resp|
				@year = eval(resp.response.body)[1][-1].to_i
				debug(@year)
				download(URL+@list+@year.to_s) do |resp|
					@month = eval(resp.response.body)[1][-1].to_i
					debug(@month)
					download(URL+@list+@year.to_s+"/"+(0 if @month < 10).to_s+@month.to_s) do |resp|
						@days = eval(resp.response.body)[1]
						debug(@days)
						@when.replace(@month.to_s, " ", @year.to_s)
						drawcalendar(@list, @year, @month, @days)
					end
				end
			end
		end
	end

			
	def changemonth(direction)
		if direction == :backward
			if @month == 1 #tempting to do "12/".next but no corresponding previous
				@year -= 1
				@month = 12
			else
				@month -= 1
			end
		end
		if direction == :forward
			if @month == 12
				@year += 1
				@month = 1
			else
				@month += 1
			end
		end
		debug(@year)
		debug(@month)
		download(URL+@list+@year.to_s+"/"+(0 if @month < 10).to_s+@month.to_s) do |resp|
			@days = eval(resp.response.body)[1]
			debug(@days)
			#@stack_cal.show
			#@stack_cal_nav.show
			@when.replace(@month.to_s, " ", @year.to_s)
			drawcalendar(@list, @year, @month, @days)
		end
	end
	

	
	#Need to be careful not to get months that don't exist (think ok back in time, within reason??)
	
		
	def init
		download(URL) do |resp|
			@list_list.items = eval(resp.response.body)[1]
			@stack_list.show
		end
	end


	#Need to clear and redraw like mailpane
	def drawcalendar(list, year, month, maildays)
		debug("Where's the calendar?")
		off=Date.new(year, month, 01).wday-1 #Offset, can't remember why I need the -1 here, but I do.
		mdays=(Date.new(year, 12, 31) << (12-month)).day #Days in the month
		rows=((mdays+off+1).to_f/7.0).ceil #Number of rows in calendar, plus 1 to compensate for -1 above. Have confused myself
		days = %w{Su Mo Tu We Th Fr Sa}
		@messagelist.clear
		@stack_cal.clear{
		days.each do |column|
			i = days.index(column)
			row = 0
			stack :left => i*40+250, :top => -30 do
				para column
				until row == rows do
					calday = i-off+7*row
					if (1..mdays) === calday #Only want to draw if greater than zero and less than max days
						if calday.to_s.length == 1
							caldaystr = "0"+calday.to_s #need "0" in front of single digits
						else
							caldaystr = calday.to_s
						end
						if maildays.include?(caldaystr+"/") 
							para make_date_link(list, year, month, calday)
						else
							para calday
						end
					else 
						para ""
					end
					row += 1
				end
			end
		end}
	end


	def make_date_link(list, year, month, day) #http://thread.gmane.org/gmane.comp.lib.shoes/4042/focus=4044
		link(day){getmails(list, year, month, day)}
	end
	

	def getmails(list, year, month, day)
		#need to fix months and days here, ie 0 on front.
		if month.to_s.length == 1
			month = "0"+month.to_s #Mr. Consistent. Done differently from the urls!
		else
			month = month.to_s
		end
		if day.to_s.length == 1
			day = "0"+day.to_s
		else
			day = day.to_s
		end
		url = "http://librelist.com/archives/"+list+"/"+year.to_s+"/"+month.to_s+"/"+day.to_s+"/json/"
		#debug(url)
		download(url) do |data|
			emails = eval(data.response.body)[1]
			#debug(emails.length)
			@messagelist.clear{
			stack  do
			emails.each do |message|
				download(url+message) do |data|
					js = JSON.parse(data.response.body)
					@messagelist.append{
						stack :margin => 30, :width => 550 do
								border black, :strokewidth => 2 
								inscription js["headers"]["Date"]
								inscription js["headers"]["From"]
								inscription js["headers"]["Subject"]
								#message body can end up in one of two places
								if js["body"] 
									para js["body"].to_s #Need to sanatize this a bit for output??
								else 
									para js["parts"][0]["body"].to_s
								end
						end
					}
				end
			end
			end}
		end
	end

	
	
	
	#Actual app stuff
	@listurl = ""
	
	@stack_cal_nav = stack do
		button "<" do
			changemonth(:backward)
		end
		@when = para "When"
		button ">" do
			changemonth(:forward)
		end
	end



	@stack_cal = stack do
		para "Calendar"
	end
	init 		
	@messagelist = stack :height => 425, :scroll => true 
	#@stack_cal.hide
	#@stack_cal_nav.hide

end
