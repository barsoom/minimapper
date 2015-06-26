require 'minimapper/entity/core'
require 'minimapper/entity/rails'

class RailsEntity
  include Minimapper::Entity::Core
  include Minimapper::Entity::Rails
end

describe Minimapper::Entity::Rails do
  it "responds to new_record?" do
    entity = RailsEntity.new
    expect(entity.new_record?).to be true
    entity.mark_as_persisted
    expect(entity.new_record?).to be false
  end

  it "responds to to_model" do
    entity = RailsEntity.new
    expect(entity.to_model).to eq(entity)
  end

  it "responds to to_key" do
    entity = RailsEntity.new
    entity.id = 5
    expect(entity.to_key).to be_nil
    entity.mark_as_persisted
    expect(entity.to_key).to eq([ 5 ])
  end

  # for rails link helpers
  it "responds to to_param" do
    entity = RailsEntity.new
    entity.id = 5
    expect(entity.to_param).to eq(5)
  end

  # for rails form helpers
  it "responds to persisted?" do
    entity = RailsEntity.new
    expect(entity).not_to be_persisted
    entity.mark_as_persisted
    expect(entity).to be_persisted
  end
end
