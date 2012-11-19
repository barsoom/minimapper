require 'minimapper/entity/convert'

module Minimapper
  module Entity
    module Attributes
      def attributes(*list)
        list.each do |attribute|
          type = nil

          if attribute.is_a?(Array)
            attribute, type = attribute
          end

          define_method(attribute) do
            attributes[attribute]
          end

          define_method("#{attribute}=") do |value|
            attributes[attribute] = Convert.new(value).to(type)
          end
        end

        @@column_names ||= []
        @@column_names |= list
      end

      def column_names
        @@column_names.map { |column| column.is_a?(Array) ? column.first : column }.map(&:to_s)
      end
    end
  end
end
