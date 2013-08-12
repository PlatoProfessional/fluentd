module Fluentd
  module Config
    module DSL
      module DSLParser
        def self.read(path)
          path = File.expand_path(path)
          data = File.read(path)
          parse(data, path)
        end

        def self.parse(source, source_path="config.rb")
          DSLElement.new('ROOT', nil).instance_eval(source, source_path).__config_element
        end

      end

      class DSLElement
        attr_accessor :name, :arg, :attrs, :elements

        def initialize(name, arg)
          @name = name
          @arg = arg
          @attrs = {}
          @elements = []
        end

        def __config_element
          Fluentd::Config::Element.new(@name, @arg, @attrs, @elements)
        end

        def method_missing(name, *args)
          raise ArgumentError, "Configuration DSL Syntax Error: only one argument allowed" if args.size > 1
          value = args.first
          @attrs[name.to_s] = value.is_a?(Symbol) ? value.to_s : value
          self
        end

        def __element(name, arg, block)
          raise ArgumentError, "#{name} block must be specified" if block.nil?
          element = DSLElement.new(name, arg)
          element.instance_exec(&block)
          @elements.push(element.__config_element)
          self
        end

        def __need_arg(name, args)
          raise ArgumentError, "#{name} block requires arguments for match pattern" if args.nil? || args.size != 1
          true
        end

        def worker(&block); __element('worker', nil, block); end
        def source(&block); __element('source', nil, block); end
        def filter(*args, &block); __need_arg('filter', args); __element('filter', args.first, block); end
        def match(*args, &block);  __need_arg('match',  args); __element('match',  args.first, block); end
        def label(*args, &block);  __need_arg('label',  args); __element('label',  args.first, block); end
      end
    end
  end
end