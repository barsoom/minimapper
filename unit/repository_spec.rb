require 'minimapper/repository'

module Test
  class ProjectMapper
    attr_accessor :repository
  end
end

describe Minimapper::Repository, "self.build" do
  it "builds a repository" do
    repository = described_class.build(:projects => Test::ProjectMapper.new)
    expect(repository).to be_instance_of(Minimapper::Repository)
    expect(repository.projects).to be_instance_of(Test::ProjectMapper)
  end

  it "memoizes the mappers" do
    repository = described_class.build(:projects => Test::ProjectMapper.new)
    expect(repository.projects.object_id).to eq(repository.projects.object_id)
  end

  it "adds a reference to the repository" do
    mapper = Test::ProjectMapper.new
    repository = described_class.build(:projects => mapper)
    expect(mapper.repository).to eq(repository)
  end

  it "does not leak between instances" do
    mapper1 = double.as_null_object
    mapper2 = double.as_null_object
    repository1 = described_class.build(:projects => mapper1)
    repository2 = described_class.build(:projects => mapper2)
    expect(repository1.projects).to eq(mapper1)
    expect(repository2.projects).to eq(mapper2)
  end
end

describe Minimapper::Repository, "#delete_all!" do
  it "removes all records by calling delete_all on all mappers" do
    project_mapper = double.as_null_object
    user_mapper = double.as_null_object

    expect(project_mapper).to receive(:delete_all)
    expect(user_mapper).to receive(:delete_all)

    repository2 = described_class.build(:projects => project_mapper, :users => user_mapper)
    repository2.delete_all!
  end
end
