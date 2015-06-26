require 'minimapper/entity/core'

class BasicEntity
  include Minimapper::Entity::Core
  attr_accessor :one, :two
end

class OtherEntity
  include Minimapper::Entity::Core
end

describe Minimapper::Entity::Core do
  it "can get and set an attributes hash" do
    entity = BasicEntity.new
    expect(entity.attributes).to eq({})
    entity.attributes = { :one => 1 }
    expect(entity.attributes).to eq({ :one => 1 })
  end

  it "does not replace the existing hash" do
    entity = BasicEntity.new
    entity.attributes = { :one => 1 }
    entity.attributes = { :two => 2 }
    expect(entity.attributes).to eq({ :one => 1, :two => 2 })
  end

  it "converts all keys to symbols" do
    entity = BasicEntity.new
    entity.attributes = { :one => 1 }
    entity.attributes = { "one" => 11 }
    expect(entity.attributes).to eq({ :one => 11 })
  end

  it "responds to id" do
    entity = BasicEntity.new
    entity.id = 10
    expect(entity.id).to eq(10)
  end

  describe "#mapper_errors" do
    it "defaults to an empty array" do
      entity = BasicEntity.new
      expect(entity.mapper_errors).to eq([])
    end

    it "can be changed" do
      entity = BasicEntity.new
      entity.mapper_errors = [ [:one, "bad"] ]
      expect(entity.mapper_errors).to eq([ [:one, "bad"] ])
    end
  end

  describe "#mapper_errors=" do
    it "makes the mapper invalid if present" do
      entity = BasicEntity.new
      entity.mapper_errors = [ [:one, "bad"] ]
      expect(entity.valid?).to be false
    end
  end

  describe "#valid?" do
    it "is true without errors" do
      entity = BasicEntity.new
      expect(entity.valid?).to be true
    end

    it "is false with errors" do
      entity = BasicEntity.new
      entity.mapper_errors = [ [:one, "bad"] ]
      expect(entity.valid?).to be false
    end
  end
end
