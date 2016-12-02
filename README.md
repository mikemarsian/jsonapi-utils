# JSONAPI::Utils 

Allows using jsonapi-utils rendering methods without defining JSONAPI Resources. This is useful when
the resources your API returns are already defined in some other way, say using ActiveModel Serializers,
and all you want is to return them in a JSONAPI compliant way (with correct content-type, error handling, etc)

# Usage

```ruby
class API::BaseController < ActionController::Base
  include JSONAPI::Utils::Response
  include JSONAPI::Utils::Request
  include JSONAPI::ActsAsResourceController
end

class API::UsersConstroller < API::BaseController
  def show
    @user = User.where(id: params[:id]).first
    if @user
      jsonapi_lean_render json: @user
    else
      errors = [{ id: 'user id', title: 'non existent user'}]
      jsonapi_render_errors json: errors, status: :not_found
    end
  end
end
```

See the original gem's Readme for more information: https://github.com/tiagopog/jsonapi-utils