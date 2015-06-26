require 'minimapper/entity/core'
require 'minimapper/entity/attributes'

module Attribute
  class User
    include Minimapper::Entity::Core
    include Minimapper::Entity::Attributes
    attribute :id, Integer
    attribute :name
  end

  class AgedUser < User
    attributes :age
  end

  class Project
    include Minimapper::Entity::Core
    include Minimapper::Entity::Attributes
    attributes :title
  end

  class Task
    include Minimapper::Entity::Core
    include Minimapper::Entity::Attributes

    attribute :due_at, DateTime
  end

  class OverridingUser
    include Minimapper::Entity::Core
    include Minimapper::Entity::Attributes
    attributes :name

    def name
      super.upcase
    end

    def name=(value)
      super(value.strip)
    end
  end
end

describe Minimapper::Entity::Attributes, "attributes without type" do
  let(:entity_class) do
    Class.new do
      include Minimapper::Entity::Core
      include Minimapper::Entity::Attributes
      attribute :name
    end
  end

  it "can be set and get with anything" do
    user = entity_class.new
    user.name = "Hello"
    expect(user.name).to eq("Hello")
    user.name = 5
    expect(user.name).to eq(5)
  end
end

describe Minimapper::Entity::Attributes do
  it "can access attributes set at construction time" do
    entity = Attribute::User.new(:id => 5)
    expect(entity.id).to eq(5)
    expect(entity.attributes[:id]).to eq(5)
  end

  it "can access attributes set through a hash" do
    entity = Attribute::User.new
    entity.attributes = { :id => 5 }
    expect(entity.id).to eq(5)
    entity.attributes = { "id" => 8 }
    expect(entity.id).to eq(8)
  end

  it "converts typed attributes" do
    entity = Attribute::User.new
    entity.id = "10"
    expect(entity.id).to eq(10)
    entity.attributes = { :id => "15" }
    expect(entity.id).to eq(15)
  end

  it "can use single line type declarations" do
    task = Attribute::Task.new(:due_at => "2012-01-01 15:00")
    expect(task.due_at).to eq(DateTime.parse("2012-01-01 15:00"))
  end

  it "sets blank values to nil" do
    user = Attribute::User.new
    user.name = "  "
    expect(user.name).to be_nil
  end

  it "symbolizes keys" do
    entity = Attribute::User.new
    entity.attributes = { "id" => "15" }
    expect(entity.attributes[:id]).to eq(15)
  end

  it "inherits attributes" do
    user = Attribute::AgedUser.new
    user.name = "Name"
    user.age = 123
    expect(user.name).to eq("Name")
    expect(user.age).to eq(123)
  end

  it "is possible to override attribute readers with inheritance" do
    user = Attribute::OverridingUser.new
    user.name = "pelle"
    expect(user.name).to eq("PELLE")
  end

  it "is possible to override attribute writers with inheritance" do
    user = Attribute::OverridingUser.new
    user.name = " 123 "
    expect(user.name).to eq("123")
  end
end

describe Minimapper::Entity::Attributes, "attributes" do
  it "returns the attributes" do
    entity = Attribute::User.new(:id => 5)
    time = Time.now
    expect(entity.attributes).to eq({ :id => 5 })
  end
end

describe Minimapper::Entity::Attributes, "self.column_names" do
  it "returns all attributes as strings" do
    # used by some rails plugins
    expect(Attribute::User.column_names).to eq([ "id", "name" ])
  end

  it "does not leak between different models" do
    expect(Attribute::Project.column_names).to eq([ "title" ])
  end
end
