require 'minimapper/entity'

class TestUser
  include Minimapper::Entity
  attributes :name
end

class TestProject
  include Minimapper::Entity
  attributes :title
end

describe Minimapper::Entity do
  let(:entity_class) do
    Class.new do
      include Minimapper::Entity
    end
  end

  it "handles base attributes" do
    entity = entity_class.new

    entity.id = 5
    expect(entity.id).to eq(5)

    time = Time.now
    entity.created_at = time
    expect(entity.created_at).to eq(time)

    entity.updated_at = time
    expect(entity.updated_at).to eq(time)
  end
end

describe Minimapper::Entity, "#==" do
  it "is equal to the exact same instance" do
    entity = build_entity(TestUser, nil)
    expect(entity).to eq(entity)
  end

  it "is equal to another instance if class and id matches" do
    entity = build_entity(TestUser,  123)
    other_entity = build_entity(TestUser,  123)
    expect(entity).to eq(other_entity)
  end

  it "is not equal to another instance if there is no id" do
    entity = build_entity(TestUser, nil)
    other_entity = build_entity(TestUser, nil)
    expect(entity).not_to eq(other_entity)
  end

  it "is not equal to another instance if ids do not match" do
    entity = build_entity(TestUser,  123)
    other_entity = build_entity(TestUser,  456)
    expect(entity).not_to eq(other_entity)
  end

  it "is not equal to another instance if classes do not match" do
    entity = build_entity(TestUser, 123)
    other_entity = build_entity(TestProject, 123)
    expect(entity).not_to eq(other_entity)
  end

  def build_entity(klass, id)
    entity = klass.new
    entity.id = id
    entity
  end
end
