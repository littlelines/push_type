module PushType
  module Customizable
    extend ActiveSupport::Concern

    def fields
      self.class.fields
    end

    def field_params
      fields.map { |k, field| field.param }
    end

    module ClassMethods

      attr_reader :fields

      def fields
        @fields ||= ActiveSupport::OrderedHash.new
      end

      def field(name, *args)
        raise ArgumentError if args.size > 2
        kind, opts = case args.size
          when 2 then args
          when 1 then args[0].is_a?(Hash) ? args.insert(0, :string) : args.insert(-1, {})
          else        [ :string, {} ]
        end

        fields[name] = field_factory(kind).new(name, opts)
        store_accessor :field_store, name

        validates name, opts[:validates] if opts[:validates]

        override_accessor fields[name]

        hook_to_self fields[name]
      end

      protected

      def field_factory(kind)
        begin
          "push_type/#{ kind }_field".camelize.constantize
        rescue NameError
          "#{ kind }_field".camelize.constantize
        end
      end

      def override_accessor(f)
        define_method "#{f.name}=".to_sym do |val|
          super f.to_json(val)
        end
        define_method f.name do
          f.from_json super()
        end
      end

      def hook_to_self(f)
        if block = f.class.node_hook_blk
          block.call(self, f)
        end
      end

    end
  end
end