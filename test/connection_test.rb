require "helper"

describe Alexa::Connection do
  let(:timestamp) { "20120808T205832Z" }

  it "calculates signature" do
    connection = Alexa::Connection.new(:access_key_id => "fake", :secret_access_key => "fake")
    connection.stubs(:timestamp).returns(timestamp)

    assert_equal "4ec8389d5a8adaaa119b08ff10d4f3549fccf48cbf56b7c9cdcd42e90b4d49ca", connection.signature
  end

  it "normalizes non string params value" do
    connection = Alexa::Connection.new(:access_key_id => "fake", :secret_access_key => "fake")
    connection.stubs(:timestamp).returns(timestamp)
    connection.params = {:custom_value => 3}

    assert_equal "custom_value=3", connection.query
  end

  it "encodes space character" do
    connection = Alexa::Connection.new(:access_key_id => "fake", :secret_access_key => "fake")
    connection.stubs(:timestamp).returns(timestamp)
    connection.params = {:custom_value => "two beers"}

    assert_equal "custom_value=two%20beers", connection.query
  end

  it "raises error when unathorized" do
    stub_request(:get, /#{API_URL}/).to_return(fixture("unathorized.txt"))
    connection = Alexa::Connection.new(:access_key_id => "wrong", :secret_access_key => "wrong")

    assert_raises Alexa::ResponseError do
      connection.get
    end
  end

  it "raises error when forbidden" do
    stub_request(:get, /#{API_URL}/).to_return(fixture("forbidden.txt"))
    connection = Alexa::Connection.new(:access_key_id => "wrong", :secret_access_key => "wrong")

    assert_raises Alexa::ResponseError do
      connection.get
    end
  end
end
