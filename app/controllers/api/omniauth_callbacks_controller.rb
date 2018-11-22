module Api
  class OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
    def redirect_callbacks
      @resource = User.from_omniauth(request.env['omniauth.auth'])
      if @resource&.persisted?
        preserve_omniauth_info

        omniauth_success
      else
        omniauth_failure
      end
    end

    def devise_mapping
      Devise.mappings[['api', 'User'.underscore].compact.join('_').to_sym]
    end

    def get_resource_from_auth_hash
      super
      @resource.email = @resource.uid
    end

    protected

    def preserve_omniauth_info
      # preserve omniauth info for success route. ignore 'extra' in SAMLResponse
      # auth response to avoid CookieOverflow.
      session['dta.omniauth.auth'] = request.env['omniauth.auth'].except('extra')
      session['dta.omniauth.params'] = request.env['omniauth.params']
    end
  end
end