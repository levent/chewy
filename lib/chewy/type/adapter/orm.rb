require 'chewy/type/adapter/base'

module Chewy
  class Type
    module Adapter
      class Orm < Base
        attr_reader :default_scope

        def initialize *args
          @options = args.extract_options!
          class_or_relation = args.first
          if class_or_relation.is_a?(relation_class)
            @target = model_of_relation(class_or_relation)
            @default_scope = class_or_relation
          else
            @target = class_or_relation
            @default_scope = all_scope
          end
          cleanup_default_scope!
        end

        def name
          @name ||= (options[:name].presence || target.name).to_s.camelize.demodulize
        end

        def identify collection
          if collection.is_a?(relation_class)
            pluck_ids(collection)
          else
            Array.wrap(collection).map do |entity|
              entity.is_a?(object_class) ? entity.public_send(primary_key) : entity
            end
          end
        end

        # Import method for ORM takes import data and import options
        #
        # Import data types:
        #
        #   * Nothing passed - imports all the model data according to type
        #     default scope
        #   * ORM scope
        #   * Objects collection
        #   * Ids collection
        #
        # Import options:
        #
        #   <tt>:batch_size</tt> - import batch size, 1000 objects by default
        #
        # Method handles destroyed objects as well. In case of objects ORM scope
        # or array passed, objects, responding with true to `destroyed?` method will be deleted
        # from index. In case of ids array passed - documents with missing records ids will be
        # deleted from index:
        #
        #   users = User.all
        #   users.each { |user| user.destroy if user.inactive? }
        #   UsersIndex::User.import users # inactive users will be deleted from index
        #   # or
        #   UsersIndex::User.import users.map(&:id) # deleted user ids will be deleted from index
        #
        # Also there is custom type option `delete_if`. It it returns `true`
        # object will be deleted from index. Note that if this option is defined and
        # return `false` Chewy will still check `destroyed?` method. This is useful
        # for paranoid objects deleting implementation.
        #
        #   define_type User, delete_if: ->{ deleted_at } do
        #     ...
        #   end
        #
        #   users = User.all
        #   users.each { |user| user.deleted_at = Time.now }
        #   UsersIndex::User.import users # paranoid deleted users will be deleted from index
        #   # or
        #   UsersIndex::User.import users.map(&:id) # user ids will be deleted from index
        #
        def import *args, &block
          options = args.extract_options!
          options[:batch_size] ||= BATCH_SIZE

          collection = args.empty? ? default_scope :
            (args.one? && args.first.is_a?(relation_class) ? args.first : args.flatten.compact)

          if collection.is_a?(relation_class)
            import_scope(collection, options, &block)
          else
            import_objects(collection, options, &block)
          end
        end

        def load *args
          load_options = args.extract_options!
          objects = args.flatten

          additional_scope = load_options[load_options[:_type].type_name.to_sym].try(:[], :scope) || load_options[:scope]

          scope = all_scope_where_ids_in(objects.map(&primary_key))
          loaded_objects = load_scope_objects(scope, additional_scope).index_by { |object| object.public_send(primary_key).to_s }

          objects.map { |object| loaded_objects[object.public_send(primary_key).to_s] }
        end

      private

        def import_objects(collection, options)
          hash = Hash[identify(collection).zip(collection)]

          indexed = hash.keys.each_slice(options[:batch_size]).map do |ids|
            batch = default_scope_where_ids_in(ids)
            if batch.empty?
              true
            else
              identify(batch).each { |id| hash.delete(id) }
              yield grouped_objects(batch)
            end
          end.all?

          deleted = hash.keys.each_slice(options[:batch_size]).map do |group|
            yield delete: hash.values_at(*group)
          end.all?

          indexed && deleted
        end

        def primary_key
          :id
        end

        def default_scope_where_ids_in(ids)
          scope_where_ids_in(default_scope, ids)
        end

        def all_scope_where_ids_in(ids)
          scope_where_ids_in(all_scope, ids)
        end

        def all_scope
          target.where(nil)
        end

        def model_of_relation relation
          relation.klass
        end

        def load_scope_objects(scope, additional_scope = nil)
          if additional_scope.is_a?(Proc)
            scope.instance_exec(&additional_scope)
          elsif additional_scope.is_a?(relation_class) && scope.respond_to?(:merge)
            scope.merge(additional_scope)
          else
            scope
          end
        end
      end
    end
  end
end
