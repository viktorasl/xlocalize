require 'spec_helper'
require 'net/http'

class HTTPResponseMock
  attr_reader :body
  attr_reader :code
  def initialize(project_files)
    @code = 200
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

class HTTPFileResponseMock
  attr_reader :body
  attr_reader :code
  def initialize(file_content)
    @code = 200
    @body = file_content
  end
end

class HTTPErrResponseMock
  attr_reader :body
  attr_reader :code
  def initialize()
    @code = 400
    @body = {"error" => "Response Error 400"}.to_json
  end
end

class HTTPMock
  attr_accessor :use_ssl
  attr_reader :reqs, :resp, :err_resp
  def initialize(resp, err_resp = nil)
    @resp = resp
    @reqs = []
    @err_resp = err_resp
  end
  def request(req, &callback)
    if not err_resp.nil? and @reqs.count == 1 then
      callback.call(@err_resp)
    else
      @reqs << req
      callback.call(@resp)
    end
  end
end

class HTTPRequestMock
end

class HTTPPullMock
  attr_accessor :use_ssl
  attr_accessor :reqs, :resps
  def initialize(project_resp, xliff_resp, plurals_resp)
    @resps = [project_resp, xliff_resp, plurals_resp]
    @reqs = []
  end
  def request(req, &callback)
    callback.call(@resps[@reqs.count])
    @reqs << req
  end
end

describe Xlocalize::WebtranslateIt do

  before(:all) do
    @loc = 'en'
    @key = 'abcd1234efgh'
    @xliff_file_id = 4355
    @plurals_file_id = 6625
  end

  it 'raises an error if response does not return master XLIFF file' do
    expect {
      Xlocalize::WebtranslateIt.new(@key, HTTPMock.new(HTTPResponseMock.new([])))
    }.to raise_error(RuntimeError)
  end
  
  it 'raises an error if response returns error' do
    http = HTTPMock.new(HTTPResponseMock.new([{
      "locale_code" => @loc,
      "id" => @xliff_file_id,
      "name" => "#{@loc}.xliff"
    }]), HTTPErrResponseMock.new)
    wti = Xlocalize::WebtranslateIt.new(@key, http)
    expect {
      wti.send_request(HTTPRequestMock.new)
    }.to raise_error(RuntimeError)
  end

  context "on initialization" do

    before(:each) do
      @http = HTTPMock.new(HTTPResponseMock.new([{
        "locale_code" => @loc,
        "id" => @xliff_file_id,
        "name" => "#{@loc}.xliff"
      }]))
      Xlocalize::WebtranslateIt.new(@key, @http)
    end

    it 'uses ssl for requests' do
      expect(@http.use_ssl).to be_truthy
    end

    it 'sends correct project data retrieval request' do
      expect(@http.reqs[0].method).to eq("GET")
      expect(@http.reqs[0].path).to eq("/api/projects/abcd1234efgh")
    end
  end

  context "pushing master files" do

    before(:each) do
      @xliff_file = File.open("./spec/fixtures/#{@loc}.xliff", 'r')
      @plurals_file = File.open("./spec/fixtures/#{@loc}.xliff_plurals.yml", 'r')
    end

    after(:each) do
      @xliff_file.close unless @xliff_file.nil?
      @plurals_file.close unless @plurals_file.nil?
    end

    context "WebtranslateIt project does not have plurals file" do

      before(:each) do
        @http = HTTPMock.new(HTTPResponseMock.new([{
          "locale_code" => @loc,
          "id" => @xliff_file_id,
          "name" => "#{@loc}.xliff"
        }]))
        @wti = Xlocalize::WebtranslateIt.new(@key, @http)
      end

      it 'plurals file is sent with master file creation request if it\'s passed' do
        @wti.push_master(@xliff_file, @plurals_file)
        expect(@http.reqs.count).to equal(3)
        expect(@http.reqs[2].method).to eq("POST")
        expect(@http.reqs[2].path).to eq("/api/projects/#{@key}/files")
      end

      it 'plurals file is not sent if it\'s not passed' do
        @wti.push_master(@xliff_file, nil)
        expect(@http.reqs.count).to equal(2)
      end

      it 'xliff file is sent with correct request' do
        @wti.push_master(@xliff_file, nil)
        expect(@http.reqs[1].method).to eq("PUT")
        expect(@http.reqs[1].path).to eq("/api/projects/#{@key}/files/#{@xliff_file_id}/locales/#{@loc}")
      end

      it 'error is raised if xliff file is not passed' do
        expect {
          @wti.push_master(nil, nil)
        }.to raise_error(NoMethodError)
      end
    end

    context "WebtranslateIt project has plurals file" do

      before(:each) do
        @http = HTTPMock.new(HTTPResponseMock.new([
          {
            "locale_code" => @loc,
            "id" => @xliff_file_id,
            "name" => "#{@loc}.xliff"
          }, {
            "locale_code" => @loc,
            "id" => @plurals_file_id,
            "name" => "plurals.yml"
          }
        ]))
        @wti = Xlocalize::WebtranslateIt.new(@key, @http)
      end

      it 'plurals file is not sent if it\'s not passed' do
        @wti.push_master(@xliff_file, nil)
        expect(@http.reqs.count).to equal(2)
      end

      it 'plurals file is sent with master file creation request if it\'s passed' do
        @wti.push_master(@xliff_file, @plurals_file)
        expect(@http.reqs.count).to equal(3)
        expect(@http.reqs[2].method).to eq("PUT")
        expect(@http.reqs[2].path).to eq("/api/projects/#{@key}/files/#{@plurals_file_id}/locales/#{@loc}")
      end
    end
  end

  context "pulling translation files" do

    it 'returns contents of xliff and plurals files' do
      project_resp = HTTPResponseMock.new([
        {
          "locale_code" => @loc,
          "id" => @xliff_file_id,
          "name" => "#{@loc}.xliff"
        }, {
          "locale_code" => @loc,
          "id" => @plurals_file_id,
          "name" => "plurals.yml"
        }
      ])
      @http = HTTPPullMock.new(project_resp, HTTPFileResponseMock.new("xliff file content"), HTTPFileResponseMock.new("plurals file content"))
      @wti = Xlocalize::WebtranslateIt.new(@key, @http)

      expect(@wti.pull('de')).to eq({'xliff' => 'xliff file content', 'plurals' => 'plurals file content'})
    end

    it 'pulls only xliff translation file if plurals file does not exist in project' do
      project_resp = HTTPResponseMock.new([
        {
          "locale_code" => @loc,
          "id" => @xliff_file_id,
          "name" => "#{@loc}.xliff"
        }
      ])
      @http = HTTPPullMock.new(project_resp, HTTPFileResponseMock.new("xliff file content"), HTTPFileResponseMock.new("plurals file content"))
      @wti = Xlocalize::WebtranslateIt.new(@key, @http)

      expect(@wti.pull('de')).to eq({'xliff' => 'xliff file content'})
    end
  end
end
