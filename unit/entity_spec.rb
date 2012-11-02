require 'minimapper/entity'

describe Minimapper::Entity do
  it "handles base attributes" do
    base = described_class.new
    base.id = 5
    base.id.should == 5

    time = Time.now
    base.created_at = time
    base.created_at.should == time

    base.updated_at = time
    base.updated_at.should == time
  end

  it "converts typed attributes" do
    base = described_class.new
    base.id = "10"
    base.id.should == 10
  end
end

class TestUser < Minimapper::Entity
  attributes :name
end

describe Minimapper::Entity, "attributes without type" do
  it "can be set and get with anything" do
    user = TestUser.new
    user.name = "Hello"
    user.name.should == "Hello"
    user.name = 5
    user.name.should == 5
  end
end

describe Minimapper::Entity, "attributes" do
  it "returns the attributes" do
    base = described_class.new(:id => 5)
    time = Time.now
    base.created_at = time
    base.attributes.should == { :id => 5, :created_at => time }
  end
end

describe Minimapper::Entity, "to_param" do
  it "responds with the id to be compatible with rails link helpers" do
    base = described_class.new(:id => 5)
    base.to_param.should == 5
  end
end

describe Minimapper::Entity, "persisted?" do
  it "responds true when there is an id (to be compatible with rails form helpers)" do
    base = described_class.new
    base.should_not be_persisted
    base.id = 5
    base.should be_persisted
  end
end
