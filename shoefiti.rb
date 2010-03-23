require 'rubygems'
require 'date'

Shoes.app do
	URL = "http://librelist.com/archives/"
	@listurl = ""
	def getlist
		download(URL+@listurl) do |list|
			@lists = eval(list.response.body)[1]
			debug(@lists)
			list_box :items => @lists do |list|
				@listurl += list.text
				getlist			
			end		
		end
	end

	getlist

	#Need to draw a calendar
	#
	#Date.today.wday gets day of the week. 0 is Sunday, etc
	
	#So have a month and a year
	def drawcalendar
	off=Date.new(2010, 03, 01).wday #Offset
	mdays=(Date.new(2010, 12, 31) << (12-03)).day #Days in the month
	rows=((mdays+off).to_f/7.0).ceil #Number of rows in calendar
		days = %w{Su Mo Tu We Th Fr Sa}
		days.each do |column|
			i = days.index(column)
			row = 0
			stack :left => i*50, :top => 0 do
				para column
				until row == rows do
					if (1..mdays) === i-off+7*row 
						para i-off+7*row
					else 
						para ""
					end#But only want to draw if greater than zero
					row += 1
				end
			end
		
			
			
		end
	
	end

	drawcalendar


end
