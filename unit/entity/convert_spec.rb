require 'minimapper/entity/convert'

describe Minimapper::Entity::Convert do
  describe "Integer" do
    it "allows integers" do
      expect(described_class.new(10).to(Integer)).to eq(10)
    end

    it "converts strings into integers" do
      expect(described_class.new('10').to(Integer)).to eq(10)
      expect(described_class.new(' 10 ').to(Integer)).to eq(10)
    end

    it "makes it nil when it can't convert" do
      expect(described_class.new(' ').to(Integer)).to be_nil
      expect(described_class.new('garbage').to(Integer)).to be_nil
    end
  end

  describe "DateTime" do
    it "allows DateTimes" do
      expect(described_class.new(DateTime.new(2013, 6, 1)).to(DateTime)).to eq(DateTime.new(2013, 6, 1))
    end

    it "converts datetime strings into datetimes" do
      expect(described_class.new('2012-01-01 20:57').to(DateTime)).to eq(DateTime.new(2012, 01, 01, 20, 57))
    end

    it "makes it nil when it can't convert" do
      expect(described_class.new(' ').to(DateTime)).to be_nil
      expect(described_class.new('garbage').to(DateTime)).to be_nil
    end
  end

  it "returns the value as-is when the type isn't specified" do
    expect(described_class.new('foobar').to(nil)).to eq('foobar')
  end

  it "raises when the type isn't known" do
    expect { described_class.new('foobar').to(:unknown) }.to raise_error(/Unknown attribute type/)
  end

  it "does not make false nil" do
    expect(described_class.new(false).to(:whatever)).to eq(false)
  end
end
