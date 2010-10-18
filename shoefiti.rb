require 'rubygems'
require 'date'
require 'json'

Shoes.app :title => "Shoefiti - Librelist Browser", :height => 700, :scroll => false do

  class Email 
    #What about what class retains in memory? Do I need to flush the class? Is that even possible?
    #Perhaps need to hand list, month, day, year attributes to draw_all. 
    #Perhaps using a class is not the best way... Use hash or array.

    attr_accessor :date, :from, :subject, :body

    def initialize(date, from, subject, body)
      @date = date
      @from = from
      @subject = subject
      @body = body
      #@thread = subject.strip of RE, FW, etc. 
      #Want to set thread. Based on subject?
    end

=begin
    def self.sort_by_thread(thread) ???
      #!
      ObjectSpace.each_object(Email) do |e|
        e.thread == 

    end
=end
    
    def self.draw_all
      ObjectSpace.each_object(Email) do |e|

        #@messagelist.append{
          $app.stack :margin => 30, :width => 550 do #Is this understood here? Some of this is not working.
            $app.border black, :strokewidth => 2 
            $app.inscription e.date
            $app.inscription e.from
            $app.inscription e.subject
            $app.para e.body.to_s
          end
        #}
      end
    end

  end


  #Need to be careful not to get months that don't exist (think ok back in time, within reason??)
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
      stack :left => i*40, :top => 10 do
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
      emails.each do |message|
        download(url+message) do |data|
          js = JSON.parse(data.response.body)
          Email.new(
            js["headers"]["Date"], 
            js["headers"]["From"], 
            js["headers"]["Subject"],
            if js["body"] 
              para js["body"]
            else 
              para js["parts"][0]["body"]
            end
          )
        end
      end
      @messagelist.clear{
        #stack do
          Email.draw_all #list, date?
        #end
      }
    end
  end
  
  
  #Actual app stuff
  URL = "http://librelist.com/archives/"

  #Try doing single list box owing to list_box troubles on shoes MinGW
  #More closely mimics the web interface
  flow :width => "100%" do
    stack :width => "40%" do 
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
      @listurl = ""
      @stack_cal_nav = stack :margin => 10 do
        button "<" do
          changemonth(:backward)
        end
        @when = para " "
        @when.style :margin => 10
        button ">" do
          changemonth(:forward)
        end
      end
    end
    @stack_cal = stack :width => "60%" do
      para " "
    end
  end
  @messagelist = stack :height => 425, :scroll => true 
  init 	

end

#What would make this useful?? 
#Grouping by thread/subject - collapsible sections. 
#For now really have to keep everything to "one day" 


