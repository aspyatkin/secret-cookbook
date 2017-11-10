module ChefCookbook
  module Secret
    class Helper
      def initialize(node)
        @node = node
        @id = 'secret'
        @instance = ::ChefCookbook::Instance::Helper.new(node)
      end

      def get(query, options = {})
        query_args = query.split(':')
        if query_args.size < 2
          ::Chef::Application.fatal!(
            "ChefCookbook::Secret::Helper.get - invalid query `#{query}`!",
            991
          )
        end

        data_bag_name = query_args.slice!(0)

        options_item = options.fetch('item', nil) || options.fetch(:item, nil)
        data_bag_item_name = options_item.nil? ? @node.chef_environment : options_item

        value_required = true
        if options.has_key?('required')
          value_required = options['required']
        elsif options.has_key?(:required)
          value_required = options[:required]
        end

        value_has_default = options.has_key?('default') || options.has_key?(:default)

        data_bag_item = nil
        begin
          data_bag_item = ::Chef::EncryptedDataBagItem.load(data_bag_name, data_bag_item_name)
        rescue ::Net::HTTPServerException, ::Chef::Exceptions::InvalidDataBagPath
          if value_required && !value_has_default
            ::Chef::Application.fatal!(
              'ChefCookbook::Secret::Helper.get - data bag item '\
              "<#{data_bag_name}::#{data_bag_item_name}> does not exist!",
              992
            )
          else
            ::Chef::Log.warn(
              'ChefCookbook::Secret::Helper.get - data bag item '\
              "<#{data_bag_name}::#{data_bag_item_name}> does not exist!"
            )
          end
        end

        prefix_fqdn = @node[@id]['prefix_fqdn']
        if options.has_key?('prefix_fqdn')
          prefix_fqdn = options['prefix_fqdn']
        elsif options.has_key?(:prefix_fqdn)
          prefix_fqdn = options[:prefix_fqdn]
        end

        if prefix_fqdn
          query_args = query_args.unshift(@instance.fqdn)
        end

        data = data_bag_item.nil? ? {} : data_bag_item.to_hash
        value_defined = false
        value = nil
        query_args.each_with_index do |arg, ndx|
          if ndx < query_args.size - 1
            data = data.fetch(arg, {})
          else
            value_defined = data.has_key?(arg)
            value = data.fetch(arg, nil)
          end
        end

        if value_required && !value_defined
          if value_has_default
            ::Chef::Log.warn(
              'ChefCookbook::Secret::Helper.get - data bag item '\
              "<#{data_bag_name}::#{data_bag_item_name}> - value with key "\
              "`#{query_args.join(':')}` is not defined, using default value."
            )
            value = options.fetch('default', nil) || options.fetch(:default, nil)
          else
            ::Chef::Application.fatal!(
              'ChefCookbook::Secret::Helper.get - data bag item '\
              "<#{data_bag_name}::#{data_bag_item_name}> - value with key "\
              "`#{query_args.join(':')}` is not defined!",
              993
            )
          end
        end

        return value
      end
    end
  end
end
