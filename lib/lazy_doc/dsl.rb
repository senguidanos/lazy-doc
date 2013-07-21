require 'json'

module LazyDoc
  module DSL
    def self.included(base)
      base.extend ClassMethods
    end

    def lazily_embed(json)
      @_embedded_doc_source = json
    end

    private

    def memoize(attribute)
      attribute_variable_name = "@_lazy_doc_#{attribute}"
      unless instance_variable_defined?(attribute_variable_name)
        instance_variable_set(attribute_variable_name, yield)
      end

      instance_variable_get(attribute_variable_name)
    end

    def extract_attribute_from(json_path)
      json_path.inject(embedded_doc) do |final_value, attribute|
        final_value[attribute.to_s]
      end
    end

    def embedded_doc
      @_embedded_doc ||= JSON.parse(@_embedded_doc_source)
    end


    module ClassMethods
      def access(attribute, options = {})
        options = default_options(attribute).merge!(options)

        json_path = [options[:via]].flatten
        transformation = options[:finally]
        sub_object_class = options[:as]

        define_method attribute do
          memoize attribute do
            value = extract_attribute_from json_path
            transformed_value = transformation.call(value)

            sub_object_class.nil? ? transformed_value : sub_object_class.new(transformed_value.to_json)
          end

        end

      end

      NO_OP_TRANSFORMATION = lambda { |value| value }
      def default_options(attribute)
        {
          via: attribute,
          finally: NO_OP_TRANSFORMATION
        }
      end

    end

  end

end