class ApplicationController < ActionController::Base
  
    class ApplicationController < ActionController::Base
        # Redirect to /chat/index after sign in
        def after_sign_in_path_for(resource)
          chat_index_path
        end
      end      
end
