require 'google/book'
require 'json'

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

get "/css/:sheet.css" do |sheet|
  sass :"css/#{sheet}"
end

get "/listings/:date" do |date|
  @listings = JSON.parse(RestClient.get("http://projects.festivalslab.com/2010/api/v1/listings.json?start=20100818&end=20100819&venue_code=Charlotte%20Square%20Gardens"))
  puts @listings.first
  haml :listings
end

get "/search/:query" do |query|
  @entries = Google::Book.search(query, :count => 25)
  haml :index
end

get %r{/json/([a-zA-Z0-9\s]+)\/?(\d*)} do
  query = params[:captures][0]
  page = 1
  page = params[:captures][1] unless params[:captures][1] == ""
  content_type :json
  entries = Google::Book.search(query, :count => 20, :page => page)
  entries.to_json
end
  