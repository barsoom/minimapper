require 'minimapper/entity/core'
require 'minimapper/entity/validation'

class ValidatableEntity
  include Minimapper::Entity::Core
  include Minimapper::Entity::Validation

  attr_accessor :name
  validates :name, :presence => true
end

describe Minimapper::Entity::Validation do
  it "includes active model validations" do
    entity = ValidatableEntity.new
    expect(entity).not_to be_valid
    entity.name = "Joe"
    expect(entity).to be_valid
  end

  describe "#mapper_errors=" do
    it "adds an error to the errors collection" do
      entity = ValidatableEntity.new
      entity.name = "Joe"
      expect(entity).to be_valid
      entity.mapper_errors = [ [:name, "must be unique"] ]
      expect(entity).not_to be_valid
      expect(entity.errors[:name]).to eq(["must be unique"])
    end
  end
end
