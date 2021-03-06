module Neo4j::Shared
  module Initialize
    extend ActiveSupport::Concern

    # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
    # so that we don't have to care if the node is wrapped or not.
    # @return self
    def wrapper
      self
    end

    private

    def convert_and_assign_attributes(properties)
      @attributes ||= self.class.attributes_nil_hash.dup
      stringify_attributes!(@attributes, properties)
      self.default_properties = properties
      self.class.declared_property_manager.convert_properties_to(self, :ruby, @attributes)
    end

    def stringify_attributes!(attr, properties)
      properties.each_pair do |k, v|
        key = self.class.declared_property_manager.string_key(k)
        attr[key] = v
      end
    end
  end
end
