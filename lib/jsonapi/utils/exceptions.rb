require 'jsonapi/utils/version'

module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecordBase < ::JSONAPI::Exceptions::Error
        attr_reader :object

        def initialize(object)
          @object = object
        end

        def errors
          object.errors.messages.flat_map do |key, messages|
            messages.map do |message|
              error_meta = error_base
                               .merge(title: title_member(key, message))
                               .merge(id: id_member(key))
                               .merge(source_member(key))
              JSONAPI::Error.new(error_meta)
            end
          end
        end

        protected

        def id_member(key)
          id = resource_key_for(key)
          key_formatter = JSONAPI.configuration.key_formatter
          key_formatter.format(id).to_sym
        end

        # Determine if this is a foreign key, which will need to look up its
        # matching association name.
        def resource_key_for(key)
          if defined?(foreign_keys) && foreign_keys.try(:include?, key)
            relationships.find { |r| r.foreign_key == key }.name.to_sym
          else
            key
          end
        end

        def source_member(key)
          Hash.new.tap do |hash|
            resource_key = resource_key_for(key)

            # Pointer should only be created for whitelisted attributes.
            return hash unless defined?(resource) && (resource.fetchable_fields.include?(resource_key) || key == :base)

            id = id_member(key)

            hash[:source] = {}
            hash[:source][:pointer] =
                # Relationship
                if defined?(relationship_keys) && relationship_keys.try(:include?, resource_key)
                  "/data/relationships/#{id}"
                  # Base
                elsif key == :base
                  '/data'
                  # Attribute
                else
                  "/data/attributes/#{id}"
                end
          end
        end

        def title_member(key, message)
          if key == :base
            message
          else
            resource_key = resource_key_for(key)
            [resource_key.to_s.tr('.', '_').humanize, message].join(' ')
          end
        end

        def error_base
          {
              code: JSONAPI::VALIDATION_ERROR,
              status: :unprocessable_entity
          }
        end

      end

      class ActiveRecord < ActiveRecordBase
        attr_reader :resource, :relationships, :relationship_keys, :foreign_keys

        def initialize(object, resource_klass, context)
          @object = object
          @resource = resource_klass.new(object, context)

          # Need to reflect on resource's relationships for error reporting.
          @relationships     = resource_klass._relationships.values
          @relationship_keys = @relationships.map(&:name).map(&:to_sym)
          @foreign_keys      = @relationships.map(&:foreign_key).map(&:to_sym)
        end
      end

      class BadRequest < ::JSONAPI::Exceptions::Error
        def code
          '400'
        end

        def errors
          [JSONAPI::Error.new(
            code: code,
            status: :bad_request,
            title: 'Bad Request',
            detail: 'This request is not supported.'
          )]
        end
      end

      class InternalServerError < ::JSONAPI::Exceptions::Error
        def code
          '500'
        end

        def errors
          [JSONAPI::Error.new(
            code: code,
            status: :internal_server_error,
            title: 'Internal Server Error',
            detail: 'An internal error ocurred while processing the request.'
          )]
        end
      end
    end
  end
end
