# encoding: utf-8
require 'net/http'
require 'open-uri'
require 'uri'
require 'iconv'
require 'debugger'
require 'net/smtp'
require 'nokogiri'
require 'pp'

class RegisterFuyou

  attr_accessor :root_url
  def initialize
    @root_url = "http://wsgh.sxmch.com/"
  end

  def send_email(to,opts={})
    opts[:server]      ||= 'smtp.126.com'
    opts[:from]        ||= 'wxy830827@126.com'
    opts[:from_alias]  ||= 'Wang Xinyu'
    opts[:subject]     ||= "Record"
    opts[:body]        ||= "Important stuff!"

    msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

    #{opts[:body]}
END_OF_MESSAGE

    Net::SMTP.start(opts[:server],25, '126.com', 'wxy830827','19830827', :plain) do |smtp|
      smtp.send_message msg, opts[:from], to
    end
  end

  def doGet url
    result = Net::HTTP.get(URI.parse(URI.encode(url)))
    Iconv.iconv('utf-8', "gb2312", result)[0]
  end

  def getDetail content

    if (content && content[0] =~ /ZhuanJia_Tool/).nil?
      puts 'did not get record'
    else
      pp 'really get one'
      subPath = content[0].match(/ZhuanJia.*\"/)
      result = doGet "#{root_url}#{subPath}"
      puts result
      file = File.new('/tmp/record.txt', 'w')
      file.write(result)
      file.close
      number = result.match(/yanse_hongse\">(\d*)</)[1]
      send_email "30540047@qq.com", :body => number
      send_email "pipi3891@qq.com", :body => number
      send_email "stellashi@tencent.com", :body => number
      send_email "xywang@thoughtworks.com", :body => number
    end
  end

  def doReq data
    unless File.exist?('/tmp/record.txt')
      puts data
      uri = URI.parse(data["url"])
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(data)

      response = http.request(request)
      content = Iconv.iconv('utf-8', "gb2312", response.body)
      #puts '-----------------------------------------'
      #puts content
      getDetail content
    end
  end

  def getRecord args
    if args[0]
      data = {
          "txtHZName" => Iconv.iconv('gb2312', 'utf-8', "王倩"),
          "txtIDNumber" => "610104198201150524",
          "txtTel" => "18991334120",
          "txtRQ" => "2013-10-30",
          "ddlBC" => "9:00-10:00",
          "rbFZ" => "1",
          "enterance" => "http://wsgh.sxmch.com/ZhuanJia_Info.asp?j_NDi0MtMnngf=MjIz"
      }
    else
      data = {
          "txtHZName" => Iconv.iconv('gb2312', 'utf-8', "史卉萍"),
          "txtIDNumber" => "610104198308190623",
          "txtTel" => "18092648155",
          "txtRQ" => "2013-10-31",
          "ddlBC" => "9:00-10:00",
          "rbFZ" => "1",
          "enterance" => "http://wsgh.sxmch.com/ZhuanJia_Info.asp?j_NDi0MtMnngf=Njc="
      }
    end
    unless File.exist?('/tmp/record.txt')
      doc = Nokogiri::HTML(open(data["enterance"]))
      doc.css('table.ziti_12 tr').each do |tr|
        #pp '<<<<<<<<<<<<<<<<'
        #pp Iconv.iconv('utf-8', "gb2312", tr.inner_html.gsub(/\t|\n|\r/,''))
        #pp '>>>>>>>>>>>>>>>>>'

        if tr.content.include? data["txtRQ"]
          pp Iconv.iconv('utf-8', "gb2312",tr.inner_html.gsub(/\t|\n|\r/,''))

          a = tr.css('a:last')
          register_url = a.attribute('href').value
          pp "register_url = #{register_url}"
          post_url = getPostUrl(URI.encode("#{root_url}#{register_url}"))
          pp "post_url = #{post_url}"
          data["url"] = URI.encode "#{root_url}#{post_url}"

          time_range = tr.css('td:nth-child(2)')[0]
          if time_range.content.include? "上"
            pp 'can order at 上午'
            %w(8:00-9:00 9:00-10:00 10:00-11:00 11:00-12:00).each do |time|
              data["ddlBC"] = time
              doReq data
            end
          elsif time_range.content.include? "下"
            pp 'can order at 下午'
            %w(14:00-15:00 15:00-16:00 16:00-17:00).each do |time|
              data["ddlBC"] = time
              doReq data
            end
          end
        end
      end
    end

  end

  def getPostUrl page_url
    post_url = ''
    doc = Nokogiri::HTML(open(page_url))
    doc.css('form[name=form1]').each do |form|
      #pp 'one form'
      #pp Iconv.iconv('utf-8', "gb2312", form.inner_html.gsub(/\r|\t|\n/,''))
      post_url = form.attribute('action').value
    end
    post_url
  end

end

registerFuyou = RegisterFuyou.new

registerFuyou.getRecord ARGV

