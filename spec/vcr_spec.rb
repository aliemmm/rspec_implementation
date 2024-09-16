require "spec_helper"

RSpec.describe "VCR" do
  it "includes method on its matching criteria" do
    VCR.use_cassette("any-cassette") do |cassette|
      expect(cassette.match_requests_on).to include(:method)
    end
  end

  it "includes uri on its matching criteria" do
    VCR.use_cassette("any-cassette") do |cassette|
      expect(cassette.match_requests_on).to include(:uri)
    end
  end

  it "includes body on its matching criteria" do
    VCR.use_cassette("any-cassette") do |cassette|
      expect(cassette.match_requests_on).to include(:body)
    end
  end
end
