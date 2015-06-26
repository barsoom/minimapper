require "spec_helper"
require "minimapper/entity/core"
require "minimapper/mapper"

class Project
  include Minimapper::Entity::Core
end

class User
  include Minimapper::Entity::Core

  attr_accessor :projects_are_eager_loaded
end

class ProjectMapper < Minimapper::Mapper
  private

  class Record < ActiveRecord::Base
    attr_protected :visible

    validates :email,
      :uniqueness => true,
      :allow_nil => true

    self.table_name = :projects
    self.mass_assignment_sanitizer = :strict
  end
end

class UserMapper < Minimapper::Mapper
  default_include :projects

  def after_find(entity, record)
    entity.projects_are_eager_loaded = record.projects.loaded?
  end

  private

  class Record < ActiveRecord::Base
    self.table_name = :users
    self.mass_assignment_sanitizer = :strict

    has_many :projects, :class_name => ProjectMapper::Record, :foreign_key => :user_id
  end
end

describe Minimapper::Mapper, "self.default_include" do
  it "eager loads the associated data by default" do
    user = User.new
    UserMapper.new.create!(user)

    project = Project.new
    project.attributes = { :user_id => user.id }
    ProjectMapper.new.create!(project)

    user = UserMapper.new.first
    expect(user.projects_are_eager_loaded).to be true
  end
end

describe Minimapper::Mapper do
  let(:mapper) { ProjectMapper.new }
  let(:entity_class) { Project }

  it "can set and get repository" do
    mapper.repository = :repository_instance
    expect(mapper.repository).to eq(:repository_instance)
  end

  describe "#create" do
    it "sets an id on the entity" do
      entity1 = build_valid_entity
      expect(entity1.id).to be_nil
      mapper.create(entity1)
      expect(entity1.id).to be > 0

      entity2 = build_valid_entity
      mapper.create(entity2)
      expect(entity2.id).to eq(entity1.id + 1)
    end

    it "marks the entity as persisted" do
      entity1 = build_valid_entity
      expect(entity1).not_to be_persisted
      mapper.create(entity1)
      expect(entity1).to be_persisted
    end

    it "returns the id" do
      id = mapper.create(build_valid_entity)
      expect(id).to be_kind_of(Fixnum)
      expect(id).to be > 0
    end

    it "does not store by reference" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.last.object_id).not_to eq(entity.object_id)
      expect(mapper.last.attributes[:name]).to eq("test")
    end

    it "validates the record before saving" do
      entity = entity_class.new
      def entity.valid?
        false
      end
      expect(mapper.create(entity)).to be false
    end

    it "calls before_save and after_save on the mapper" do
      entity = build_valid_entity
      record = ProjectMapper::Record.new
      allow(ProjectMapper::Record).to receive_messages(:new => record)
      expect(mapper).to receive(:before_save).with(entity, record)
      expect(mapper).to receive(:after_save).with(entity, record)
      mapper.create(entity)
    end

    it "calls after_create on the mapper" do
      entity = build_valid_entity
      record = ProjectMapper::Record.new
      allow(ProjectMapper::Record).to receive_messages(:new => record)
      expect(mapper).to receive(:after_create).with(entity, record)
      mapper.create(entity)
    end

    it "does not call after_save or after_create if the save fails" do
      entity = entity_class.new
      def entity.valid?
        false
      end
      expect(mapper).to receive(:before_save)
      expect(mapper).not_to receive(:after_save)
      expect(mapper).not_to receive(:after_create)
      mapper.create(entity)
    end

    it "does not include protected attributes" do
      # because it leads to exceptions when mass_assignment_sanitizer is set to strict
      entity = build_entity(:visible => true, :name => "Joe")
      mapper.create(entity)

      stored_entity = mapper.find(entity.id)
      expect(stored_entity.attributes[:visible]).to be_nil
      expect(stored_entity.attributes[:name]).to eq("Joe")

      entity = Project.new
      entity.attributes = { :visible => true, :name => "Joe" }
      allow(ProjectMapper::Record).to receive_messages(:protected_attributes => [])
      expect { mapper.create(entity) }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end

    it "copies record validation errors to entity" do
      old_entity = build_entity(:email => "joe@example.com")
      mapper.create(old_entity)
      expect(old_entity.mapper_errors).to eq([])

      new_entity = build_entity(:email => "joe@example.com")
      mapper.create(new_entity)
      expect(new_entity.mapper_errors).to eq([ [:email, "has already been taken"] ])
    end

    it "can revalidate on record validation errors" do
      old_entity = build_entity(:email => "joe@example.com")
      mapper.create(old_entity)

      new_entity = build_entity(:email => "joe@example.com")
      mapper.create(new_entity)
      expect(new_entity.mapper_errors).to eq([ [:email, "has already been taken"] ])

      new_entity.attributes = { :email => "something.else@example.com" }
      mapper.create(new_entity)
      expect(new_entity).to be_valid
    end
  end

  describe "#create!" do
    it "can create records" do
      entity = build_valid_entity
      mapper.create!(entity)
      expect(entity).to be_persisted
    end

    it "raises Minimapper::EntityInvalid when the entity is invalid" do
      entity = entity_class.new
      def entity.valid?
        false
      end
      expect { mapper.create!(entity) }.to raise_error(Minimapper::EntityInvalid)
    end
  end

  describe "#find" do
    it "returns an entity matching the id" do
      entity = build_valid_entity
      mapper.create(entity)
      found_entity = mapper.find(entity.id)
      expect(found_entity.attributes[:name]).to eq("test")
      expect(found_entity.id).to eq(entity.id)
      expect(found_entity).to be_kind_of(Minimapper::Entity::Core)
    end

    it "supports string ids" do
      entity = build_valid_entity
      mapper.create(entity)
      mapper.find(entity.id.to_s)
    end

    it "does not return the same instance" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.find(entity.id).object_id).not_to eq(entity.object_id)
      expect(mapper.find(entity.id).object_id).not_to eq(mapper.find(entity.id).object_id)
    end

    it "calls after_find on the mapper" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper).to receive(:after_find)
      found_entity = mapper.find(entity.id)
    end

    it "returns an entity marked as persisted" do
      entity = build_valid_entity
      mapper.create(entity)
      found_entity = mapper.find(entity.id)
      expect(found_entity).to be_persisted
    end

    it "fails when an entity can not be found" do
      expect { mapper.find(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#find_by_id" do
    it "returns an entity matching the id" do
      entity = build_valid_entity
      mapper.create(entity)
      found_entity = mapper.find_by_id(entity.id)
      expect(found_entity.attributes[:name]).to eq("test")
      expect(found_entity.id).to eq(entity.id)
      expect(found_entity).to be_kind_of(Minimapper::Entity::Core)
    end

    it "supports string ids" do
      entity = build_valid_entity
      mapper.create(entity)
      mapper.find_by_id(entity.id.to_s)
    end

    it "does not return the same instance" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.find_by_id(entity.id).object_id).not_to eq(entity.object_id)
      expect(mapper.find_by_id(entity.id).object_id).not_to eq(mapper.find_by_id(entity.id).object_id)
    end

    it "returns nil when an entity can not be found" do
      expect(mapper.find_by_id(-1)).to be_nil
    end
  end

  describe "#all" do
    it "returns all entities in undefined order" do
      first_created_entity = build_valid_entity
      second_created_entity = build_valid_entity
      mapper.create(first_created_entity)
      mapper.create(second_created_entity)
      all_entities = mapper.all
      expect(all_entities.map(&:id)).to include(first_created_entity.id)
      expect(all_entities.map(&:id)).to include(second_created_entity.id)
      expect(all_entities.first).to be_kind_of(Minimapper::Entity::Core)
    end

    it "does not return the same instances" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.all.first.object_id).not_to eq(entity.object_id)
      expect(mapper.all.first.object_id).not_to eq(mapper.all.first.object_id)
    end
  end

  describe "#first" do
    it "returns the first entity" do
      first_created_entity = build_valid_entity
      mapper.create(first_created_entity)
      mapper.create(build_valid_entity)
      expect(mapper.first.id).to eq(first_created_entity.id)
      expect(mapper.first).to be_kind_of(entity_class)
    end

    it "does not return the same instance" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.first.object_id).not_to eq(entity.object_id)
      expect(mapper.first.object_id).not_to eq(mapper.first.object_id)
    end

    it "returns nil when there is no entity" do
      expect(mapper.first).to be_nil
    end
  end

  describe "#last" do
    it "returns the last entity" do
      last_created_entity = build_valid_entity
      mapper.create(build_valid_entity)
      mapper.create(last_created_entity)
      expect(mapper.last.id).to eq(last_created_entity.id)
      expect(mapper.last).to be_kind_of(entity_class)
    end

    it "does not return the same instance" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.last.object_id).not_to eq(entity.object_id)
      expect(mapper.last.object_id).not_to eq(mapper.last.object_id)
    end

    it "returns nil when there is no entity" do
      expect(mapper.last).to be_nil
    end
  end

  describe "#reload" do
    it "reloads the given record" do
      entity = build_entity(:email => "foo@example.com")
      mapper.create(entity)
      entity.attributes[:email] = "test@example.com"
      mapper.reload(entity)
      entity.attributes[:email] = "foo@example.com"
      expect(mapper.reload(entity).object_id).not_to eq(entity.object_id)
    end
  end

  describe "#count" do
    it "returns the number of entities" do
      mapper.create(build_valid_entity)
      mapper.create(build_valid_entity)
      expect(mapper.count).to eq(2)
    end
  end

  describe "#update" do
    it "updates" do
      entity = build_valid_entity
      mapper.create(entity)

      entity.attributes = { :name => "Updated" }
      expect(mapper.last.attributes[:name]).to eq("test")

      mapper.update(entity)
      expect(mapper.last.id).to eq(entity.id)
      expect(mapper.last.attributes[:name]).to eq("Updated")
    end

    it "does not update and returns false when the entity isn't valid" do
      entity = build_valid_entity
      mapper.create(entity)

      def entity.valid?
        false
      end

      expect(mapper.update(entity)).to be false
      expect(mapper.last.attributes[:name]).to eq("test")
    end

    it "calls before_save and after_save on the mapper" do
      entity = build_valid_entity
      mapper.create(entity)

      record = ProjectMapper::Record.last
      allow(ProjectMapper::Record).to receive_messages(:find_by_id => record)

      expect(mapper).to receive(:before_save).with(entity, record)
      expect(mapper).to receive(:after_save).with(entity, record)
      mapper.update(entity)
    end

    it "does not call after_create" do
      entity = build_valid_entity
      mapper.create(entity)

      record = ProjectMapper::Record.last
      allow(ProjectMapper::Record).to receive_messages(:find_by_id => record)

      expect(mapper).to receive(:after_save)
      expect(mapper).not_to receive(:after_create)
      mapper.update(entity)
    end

    it "returns true" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(mapper.update(entity)).to eq(true)
    end

    it "fails when the entity does not have an id" do
      entity = build_valid_entity
      expect { mapper.update(entity) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "fails when the entity no longer exists" do
      entity = build_valid_entity
      mapper.create(entity)
      mapper.delete_all
      expect { mapper.update(entity) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not include protected attributes" do
      entity = Project.new
      mapper.create(entity)

      entity.attributes = { :visible => true, :name => "Joe" }
      mapper.update(entity)
      stored_entity = mapper.find(entity.id)
      expect(stored_entity.attributes[:visible]).to be_nil
      expect(stored_entity.attributes[:name]).to eq("Joe")

      allow(ProjectMapper::Record).to receive_messages(:protected_attributes => [])
      expect { mapper.update(entity) }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end

    it "copies record validation errors to entity" do
      old_entity = build_entity(:email => "joe@example.com")
      mapper.create(old_entity)

      new_entity = Project.new
      mapper.create(new_entity)
      expect(new_entity.mapper_errors).to eq([])

      new_entity.attributes = { :email => "joe@example.com" }
      mapper.update(new_entity)
      expect(new_entity.mapper_errors).to eq([ [:email, "has already been taken"] ])
    end

    it "can revalidate on record validation errors" do
      old_entity = build_entity(:email => "joe@example.com")
      mapper.create(old_entity)

      new_entity = Project.new
      mapper.create(new_entity)
      expect(new_entity.mapper_errors).to eq([])

      new_entity.attributes = { :email => "joe@example.com" }
      mapper.update(new_entity)
      expect(new_entity.mapper_errors).to eq([ [:email, "has already been taken"] ])

      new_entity.attributes = { :email => "something.else@example.com" }
      mapper.update(new_entity)
      expect(new_entity).to be_valid
    end
  end

  describe "#update!" do
    it "can update records" do
      entity = build_valid_entity
      mapper.create(entity)
      entity.attributes[:email] = "updated@example.com"
      mapper.update!(entity)
      expect(mapper.reload(entity).attributes[:email]).to eq("updated@example.com")
    end

    it "raises Minimapper::EntityInvalid when the entity is invalid" do
      entity = build_valid_entity
      mapper.create(entity)
      def entity.valid?
        false
      end
      expect { mapper.update!(entity) }.to raise_error(Minimapper::EntityInvalid)
    end
  end

  describe "#delete" do
    it "removes the entity" do
      entity = build_valid_entity
      removed_entity_id = entity.id
      mapper.create(entity)
      mapper.create(build_valid_entity)
      mapper.delete(entity)
      expect(mapper.all.size).to eq(1)
      expect(mapper.first.id).not_to eq(removed_entity_id)
    end

    it "marks the entity as no longer persisted" do
      entity = build_valid_entity
      mapper.create(entity)
      expect(entity).to be_persisted
      mapper.delete(entity)
      expect(entity).not_to be_persisted
    end

    it "fails when the entity does not have an id" do
      entity = entity_class.new
      expect { mapper.delete(entity) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "fails when the entity can not be found" do
      entity = entity_class.new
      entity.id = -1
      expect { mapper.delete(entity) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#delete_by_id" do
    it "removes the entity" do
      entity = build_valid_entity
      mapper.create(entity)
      mapper.create(build_valid_entity)
      mapper.delete_by_id(entity.id)
      expect(mapper.all.size).to eq(1)
      expect(mapper.first.id).not_to eq(entity.id)
    end

    it "fails when an entity can not be found" do
      expect { mapper.delete_by_id(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#delete_all" do
    it "empties the mapper" do
      mapper.create(build_valid_entity)
      mapper.delete_all
      expect(mapper.all).to eq([])
    end
  end

  private

  def build_valid_entity
    entity = entity_class.new
    entity.attributes = { :name => 'test' }
    entity
  end

  def build_entity(attributes)
    entity = Project.new
    entity.attributes = attributes
    entity
  end
end
