module JSONAPI
  module Utils
    module Response
      module Renders

        # Respond with HEAD and the provided status. If status not provided, 200 will be returned
        def jsonapi_head_render(status: nil)
          head status || :ok
        rescue => e
          handle_exceptions(e)
        ensure
          correct_media_type
        end

        # Render provided json in a JSON-API compatible way. This render works without defining JSONAPI Resources.
        # Useful in cases when your resources are defined otherwise, for example using ActiveModel Serializers
        def jsonapi_lean_render(json:, status: nil)
          render json: json, status: status || :ok
        rescue => e
          handle_exceptions(e)
        ensure
          correct_media_type
        end

        def jsonapi_render(json:, status: nil, options: {})
          body = jsonapi_format(json, options)
          render json: body, status: status || @_response_document.status
        rescue => e
          handle_exceptions(e)
        ensure
          correct_media_type
        end

        def jsonapi_render_errors(exception = nil, json: nil, status: nil)
          body   = jsonapi_format_errors(exception || json)
          status = status || body.try(:first).try(:[], :status)
          render json: { errors: body }, status: status
        ensure
          correct_media_type
        end

        def jsonapi_render_internal_server_error
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::InternalServerError.new)
        end

        def jsonapi_render_bad_request
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::BadRequest.new)
        end

        def jsonapi_render_not_found(exception)
          id = exception.message.match(/=([\w-]+)/).try(:[], 1) || '(no identifier)'
          jsonapi_render_errors(JSONAPI::Exceptions::RecordNotFound.new(id))
        end

        def jsonapi_render_not_found_with_null
          render json: { data: nil }, status: 200
        end
      end
    end
  end
end
