require 'google/book'
require 'json'
require 'chronic'

class Google::Book::Response 
  def to_json(*a)    
    {
      'data'         => {
        'total_results' => self.total_results,
        'entries' => self.entries
      }
    }.to_json(*a)
  end
end

class Google::Book::Entry
  def to_json(*a)
    {
      'cover' => self.cover,
      'creators' => self.creators,
      'date' => self.date,
      'description' => self.description,
      'format' => self.format,
      'info' => self.info,
      'preview' => self.preview,
      'publisher' => self.publisher,
      'subjects' => self.subjects,
      'title' => self.title,
      'isbn' => self.isbn
    }.to_json(*a)
  end
end

class Google::Book::Cover
  def to_json(*a)
    {
      'thumbnail' => self.thumbnail,
      'small' => self.small,
      'medium' => self.medium,
      'large' => self.large,
      'extra_large' => self.extra_large
    }.to_json(*a)
  end
end

helpers do
  def friendly_date(str)
    begin
      date = Chronic.parse(str)
      date.strftime('%e %B %Y') unless date.nil?
    rescue
      return
    end
  end
  
  def friendly_standard_date(str) 
    begin
      date = Time.parse(str)
      date.strftime('%e %B %Y') unless date.nil?
    rescue
      return
    end
  end
end

get "/css/:sheet.css" do |sheet|
  scss :"css/#{sheet}"
end

get "/" do
  @date_range = (Date.parse('2010-08-14')..Date.parse('2010-08-30')).to_a
  haml :index
end

get "/listings/:date" do |date| 
  @start_date = date.gsub('-', '').to_i
  @end_date = @start_date + 1
  @display_date = Chronic.parse(date)
  url = "http://projects.festivalslab.com/2010/api/v1/listings.json?start=#{@start_date}&end=#{@end_date}&venue_code=Charlotte%20Square%20Gardens"
  listings = RestClient.get(url)
  @listings = JSON.parse(listings)
  haml :listings
end

get "/books/detail/:isbn" do |isbn|
  @book = Google::Book.search(isbn, :count => 25).entries.first
  haml :details
end

get "/books/:query" do |query|
  searches = query.split(/,|and|&|with/).unshift(query).uniq.map do |q|
    Google::Book.search(q, :count => 25)
  end
  all_authors = searches.map do |search|
    search.entries.map do |entry|
      entry.creators.split(/,\s?/)
    end
  end
  @authors = all_authors.flatten.uniq.keep_if { |author| query.include? author }
  @searches = @authors.map do |author|
    Google::Book.search(author, :count => 25)
  end
  if !@authors.length
    @searches = searches
  end
  haml :books
end

get "/guardian/author/:author" do |author|
  guardian_response = RestClient.get "http://content.guardianapis.com/search?q=%22#{CGI::escape(author)}%22&section=books&format=json&api-key=chdscot&show-fields=thumbnail"
  json_response = JSON.parse(guardian_response)
  @res = json_response["response"]
  @author = author
  haml :guardian_author
end

get %r{/json/([a-zA-Z0-9\s]+)\/?(\d*)} do
  query = params[:captures][0]
  page = 1
  page = params[:captures][1] unless params[:captures][1] == ""
  content_type :json
  entries = Google::Book.search(query, :count => 20, :page => page)
  entries.to_json
end
  