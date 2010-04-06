require 'rubygems'
require 'date'
require 'json'

Shoes.app :title => "Shoefiti - Librelist Browser", :height => 700, :scroll => false do
	
	#Clever, but utimately useless if want to re-select something. I.e. different mailing list.
	#Perhaps mix in with Classes??
	#only works once. 
	
	#class listsel
	#	url
		#extend the list_box method? I.e. what gets executed on selection?
		#
	
#must reset
	
	@stack_list = stack :margin => 10 do
		
		@list_list = list_box do |list| 
			@stack_day.hide
			download(URL+list.text) do |resp|
				@list_year.items = eval(resp.response.body)[1]
				@stack_year.show
			end
		end
	end


	@stack_year = stack :margin => 10 do
		@list_year = list_box do |year|

			download(URL+@list_list.text+year.text) do |resp|
				@list_day.items =  eval(resp.response.body)[1]
				@stack_day.show
			end
		end
	end

	@stack_day = stack :margin => 10 do
		@list_day = list_box do |day|
			download(URL+@list_list.text+@list_year.text+day.text) do |resp|
				@place = eval(resp.response.body)[0].split("/")
				drawcalendar(@place.pop.to_i, @place.pop.to_i, @place.pop.to_s, eval(resp.response.body)[1])
				drawmailpane
			end
		end
	end




	
	def init
		download(URL) do |resp|
			@list_list.items = eval(resp.response.body)[1]
			@stack_list.show
		end
	end

=begin
			@place = eval(list.response.body)[0].split("/")
			#debug(@lists)
			#debug(@place)
			stack :margin => 10 do
				@loading.hide
				@animate.stop
				@loaded.show
				if @place.length < 5 #Need to break out of this once we get to the list of days. Odd array length due to split on /
					
					make_list_box(@lists)

					
					#list_box :items => @lists do |list|
					#	debug(@lists)
					#	@listurl += list.text
					#	getlist
					#end
				else
					#debug("Pop1 "+@place.pop) #Turning on these debugs will break app since popping items from array
					#debug("Pop2 "+@place.pop)
					drawcalendar(@place.pop.to_i, @place.pop.to_i, @place.pop.to_s, @lists)
					drawmailpane #Can't draw mailpane before now, as otherwise threading in getlist downloads results in drop downs appearing below mailpane
				end	
			end		
		end
	end


	#This half works and makes sure lists retain their 'lists'
	def make_list_box(lists)
		list_box :items => lists do |list|
			@listurl += list.text
			debug(lists)
			getlist
		end
	end
=end

	#Need to clear and redraw like mailpane
	def drawcalendar(month, year, list, maildays)
		off=Date.new(year, month, 01).wday-1 #Offset, not sure why I need the -1 here, but I do.
		mdays=(Date.new(year, 12, 31) << (12-month)).day #Days in the month
		rows=((mdays+off+1).to_f/7.0).ceil #Number of rows in calendar, plus 1 to compensate for -1 above. Have confused myself
		days = %w{Su Mo Tu We Th Fr Sa}
		days.each do |column|
			i = days.index(column)
			row = 0
			stack :left => i*40+250, :top => 0 do
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

	
	def drawmailpane
		@messagelist = stack :height => 425, :scroll => true 
	end

=begin	
	@loading = para "Loading Lists...", :margin => 10
	@animate = animate(5) do |frame|
		weight = ["bold", "normal"]
		@loading.style(:weight => weight[frame&1])	
	end
	@loaded = para "Pick list to browse", :margin => 10
	@loaded.hide
=end

	URL = "http://librelist.com/archives/"
	@listurl = ""
	


	@stack_list.hide
	@stack_year.hide
	@stack_day.hide

	init 		
	

end
