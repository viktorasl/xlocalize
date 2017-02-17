require 'spec_helper'
require 'net/http'

class HTTPResponseMock
  attr_reader :body
  def initialize(project_files)
    @body = {
      "project" => {
        "source_locale" => {
          "code" => "en"
        },
        "project_files" => project_files
      }
    }.to_json
  end
end

class HTTPMock
  attr_accessor :use_ssl
  attr_reader :req, :resp
  def initialize(resp)
    @resp = resp
  end
  def request(req, &callback)
    @req = req
    callback.call(@resp)
  end
end

describe Xlocalize::WebtranslateIt do
  it 'raises an error if response does not return master XLIFF file' do
    expect {
      Xlocalize::WebtranslateIt.new("abcd1234efgh", HTTPMock.new(HTTPResponseMock.new([])))
    }.to raise_error(RuntimeError)
  end
  describe ".initialize" do
    http = HTTPMock.new(HTTPResponseMock.new([{
      "locale_code" => "en",
      "id" => 4355,
      "name" => "en.xliff"
    }]))
    Xlocalize::WebtranslateIt.new("abcd1234efgh", http)

    it 'uses ssl for requests' do
      expect(http.use_ssl).to be_truthy
    end
    it 'sends correct project data retrieval request' do
      expect(http.req.method).to eq("GET")
      expect(http.req.path).to eq("/api/projects/abcd1234efgh")
    end
  end
end
